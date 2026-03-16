package com.evtopia.services;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import android.util.Log;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "MyFirebaseMsgService";

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // Handle the received message
        Log.d(TAG, "Message received: " + remoteMessage.getMessageId());
    }

    @Override
    public void onNewToken(String token) {
        // Handle token refresh
        Log.d(TAG, "New token: " + token);
    }
}
