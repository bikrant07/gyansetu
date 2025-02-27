const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Listen for new messages in Realtime Database
exports.sendMessageNotification = functions.database
  .ref('/messages/{chatType}/{chatId}/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    const { chatType, chatId } = context.params;

    // Don't send notification to the sender
    if (!message.userId) return;

    try {
      // Get recipient's FCM token
      const recipientId = chatType === 'private' 
        ? chatId.split('_').find(id => id !== message.userId)
        : null;

      let tokens = [];
      
      if (chatType === 'private') {
        // For private messages
        const recipientDoc = await admin.firestore()
          .collection('users')
          .doc(recipientId)
          .get();
        
        if (recipientDoc.exists && recipientDoc.data().fcmToken) {
          tokens.push(recipientDoc.data().fcmToken);
        }
      } else {
        // For public messages
        const usersSnapshot = await admin.firestore()
          .collection('users')
          .where('fcmToken', '!=', null)
          .get();
        
        tokens = usersSnapshot.docs
          .filter(doc => doc.id !== message.userId)
          .map(doc => doc.data().fcmToken);
      }

      if (tokens.length === 0) return;

      // Send notification
      await admin.messaging().sendMulticast({
        tokens,
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        notification: {
          title: chatType === 'private' ? message.userName : 'New Public Message',
          body: message.text,
          sound: 'default',
          priority: 'high',
        },
        data: {
          type: `${chatType}_message`,
          senderId: message.userId,
          senderName: message.userName,
          chatId: chatId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      });

    } catch (error) {
      console.error('Error sending notification:', error);
    }
  }); 