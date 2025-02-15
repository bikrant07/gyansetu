This web application fetches and displays scholarships from an external source. However, the source requires handling CORS (Cross-Origin Resource Sharing) to work properly in a web environment. By default, CORS is blocked for cross-origin requests in most browsers, causing the scholarship data not to load.
To avoid CORS issues, we use a service called CORS Anywhere, which acts as a proxy to allow cross-origin requests. However, since this is a free service, it requires temporary access.

Follow these steps to enable the CORS proxy:

Visit the CORS Anywhere demo page:
https://cors-anywhere.herokuapp.com/corsdemo

You’ll see a button labeled "Request temporary access to the demo server". Click it.

After clicking, you should see a message indicating that temporary access has been granted.

Once access is granted, reload the index.html page of the project in your browser. The scholarships should now be fetched and displayed properly.