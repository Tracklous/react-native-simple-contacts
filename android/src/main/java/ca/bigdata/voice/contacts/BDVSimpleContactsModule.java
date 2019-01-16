
package ca.bigdata.voice.contacts;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.ContactsContract;
import android.telephony.TelephonyManager;
import android.text.TextUtils;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Locale;

public class BDVSimpleContactsModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private static final String TAG = "BDVSimpleContactsModule";


    public BDVSimpleContactsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "BDVSimpleContacts";
    }


    @ReactMethod
    public void getContacts(final String timestamp, final Promise promise) {
        Log.d(TAG, "getContacts");

        Thread thread = new Thread() {
            @Override
            public void run() {
                Log.d(TAG, "thread started");
                Context context = getReactApplicationContext();
                if (context == null) {
                    promise.reject("1", "Null activity");
                    return;
                }
                //  ContentResolver cr = context.getContentResolver();

                JSONArray jsonA = new JSONArray();

                String selection = null;
                String[] selectionArgs = null;
                ArrayList<String> uniqueNumber = new ArrayList<>();

                String[] projectionToCheck = {ContactsContract.CommonDataKinds.Phone.CONTACT_ID, ContactsContract.CommonDataKinds.Phone._ID, ContactsContract.CommonDataKinds.Phone.RAW_CONTACT_ID, ContactsContract.CommonDataKinds.Phone.NUMBER, ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.PHOTO_URI, ContactsContract.CommonDataKinds.Phone.STATUS};
//                Cursor cursorToCheck = context.getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, projectionToCheck, null, null, ContactsContract.Contacts.SORT_KEY_PRIMARY);
                if (!TextUtils.isEmpty(timestamp)) {

                    selection = ContactsContract.CommonDataKinds.Phone.CONTACT_LAST_UPDATED_TIMESTAMP + " >= " + timestamp;
                    Log.d(TAG, "Selection is:- " + selection);

                }
                Cursor data = context.getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, projectionToCheck, selection, selectionArgs, ContactsContract.Contacts.SORT_KEY_PRIMARY);
                final int contactIdIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID);
                final int contactRawIdIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone.RAW_CONTACT_ID);
                final int contactPhoneNumberIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER);
                final int contactPhotoIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone.PHOTO_URI);
                final int contactNameIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME);
                final int rowIdIndex = data.getColumnIndex(ContactsContract.CommonDataKinds.Phone._ID);
                try {
                    while (data.moveToNext()) {
                        JSONObject json = new JSONObject();
                        json.put(
                                "key",
                                "contact_" + data.getString(contactIdIndex) + "_" + data.getString(rowIdIndex)

                        );
                        json.put(
                                "name", data.getString(contactNameIndex)

                        );
                        if (data.getString(contactPhotoIndex) != null) {
                            json.put(
                                    "avatar", data.getString(contactPhotoIndex)

                            );
                        }
                        String value = data.getString(contactPhoneNumberIndex);
                        String number = "";
                        // String code = getCountryCode(ca) != null ? getCountryCode(ca) : checkCountryCodeFromIsoCode(ca, "");
                        value = value.replaceAll(" ", "").replaceAll("-", "").replaceAll("\\p{P}", "").replaceAll("\\s+", "");
                        number = value;

                         if (value.startsWith("0")) {
                             String countryName = Locale.getDefault().getCountry();
                             number = value.substring(value.indexOf("0") + 1);
                             number = countryName + "-" + number;
                         }
                         else if (!number.contains("+")) {
                             String countryName = Locale.getDefault().getCountry();
                             number = countryName + "-" + number;
                         }
                        json.put("number", number);

                        if (!uniqueNumber.contains(number)){
                            jsonA.put(json);
                            uniqueNumber.add(number);
                        }
                    }

                } catch (JSONException je) {
                } finally {
                    data.close();
                }
                Log.d("contacts", jsonA.toString());
                promise.resolve(jsonA.toString());
            }
        };
        thread.start();
    }


    @ReactMethod
    public void getProfile(Promise promise) {
        ContentResolver cr = getCurrentActivity().getContentResolver();
        Cursor cursor = cr.query(
                ContactsContract.Profile.CONTENT_URI,
                new String[]{
                        ContactsContract.Profile.DISPLAY_NAME,
                        ContactsContract.Profile.PHOTO_THUMBNAIL_URI
                },
                null, null, null
        );
        JSONObject json = new JSONObject();

        if (cursor.moveToFirst()) {
            try {
                json.put(
                        "display",
                        cursor.getString(
                                cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                        )
                );
                json.put(
                        "avatar",
                        cursor.getString(
                                cursor.getColumnIndex(
                                        ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI
                                )
                        )
                );
            } catch (JSONException exc) {
                Log.e(TAG, exc.toString());
            }
        } else {
            Log.d(TAG, "Error retrieving profile");
        }
        cursor.close();
        promise.resolve(json.toString());
    }

    @ReactMethod
    public void findContactByNumber(String number, Promise promise) {
        ContentResolver cr = getCurrentActivity().getContentResolver();
        Uri uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(number)
        );

        JSONObject json = new JSONObject();

        Cursor cursor = cr.query(
                uri,
                new String[]{
                        ContactsContract.PhoneLookup.DISPLAY_NAME,
                        ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI
                },
                null, null, null
        );
        if (cursor.moveToFirst()) {
            try {
                json.put(
                        "display",
                        cursor.getString(
                                cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                        )
                );
                json.put(
                        "avatar",
                        cursor.getString(
                                cursor.getColumnIndex(
                                        ContactsContract.PhoneLookup.PHOTO_THUMBNAIL_URI
                                )
                        )
                );
            } catch (JSONException exc) {
                Log.e(TAG, exc.toString());
            }

        } else {
            Log.d(TAG, "Contact: Not found.");
        }
        cursor.close();
        promise.resolve(json.toString());
    }

}
