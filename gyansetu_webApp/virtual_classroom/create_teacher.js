const admin = require('firebase-admin');

const serviceAccount = require('./gyansetu-6e83b-firebase-adminsdk-ho9y3-c60aef91fa.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://gyansetu-6e83b-default-rtdb.firebaseio.com"
});

async function createTeacher(email, password, name) {
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      emailVerified: true,
      displayName: name
    });

    // Save teacher data to Firestore admins collection
    const teacherData = {
      bio: "GyanSetu Teacher",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      email: email,
      name: name,
      profileName: name,
      profileImageUrl: "",
      role: 'teacher'
    };

    // Save to admins collection
    await admin.firestore().collection('admins').doc(userRecord.uid).set(teacherData);

    console.log('Successfully created teacher:', userRecord.uid);
    return userRecord.uid;
  } catch (error) {
    console.error('Error creating teacher:', error);
    throw error;
  }
}

// Update these credentials
const teacher = {
  email: 'admin@gyansetu.com',  // Use this exact email
  password: 'nimish',           // Use this exact password
  name: 'Nimish Teacher'
};

createTeacher(teacher.email, teacher.password, teacher.name)
  .then(() => {
    console.log('Teacher created successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Failed to create teacher:', error);
    process.exit(1);
  }); 