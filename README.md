
# Introduction

This is a simple app to access Google tasks on [Garmin
ConnectIQ](https://developer.garmin.com/connect-iq/overview/) watches.

# Initial Setup

![authorization flow diagram](http://mspells.me/software/synctasks-garmin/auth_flow.svg)

1. When opening the app for the first time on the wearable<sup>(a)</sup>, it will request a validation code from Google by opening a webpage on your phone. Accept the ConnectIQ notification<sup>(b)</sup> to open the webpage the app requests in your browser.
2. After agreeing to grant the app access to your Google task lists in the browser window<sup>(c)</sup>, a code will be displayed<sup>(d)</sup>. Copy and paste this code into the <a href="https://support.garmin.com/en-US/?faq=SPo0TFvhQO04O36Y5TYRh5">settings</a> for the app<sup>(e)</sup>.
3. The wearable app should now be able to properly access your Google tasks. Enjoy!
