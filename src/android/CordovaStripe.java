package com.mipadrino.cordova.stripe;

import android.content.Context;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import com.stripe.android.ApiResultCallback;
import com.stripe.android.Stripe;
import com.stripe.android.model.Address;
import com.stripe.android.model.BankAccountTokenParams;
import com.stripe.android.model.DateOfBirth;
import com.stripe.android.model.AccountParams;
import com.stripe.android.model.Token;

public class CordovaStripe extends CordovaPlugin {

  private Stripe stripeInstance;
  private Context webViewContext;

  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    webViewContext = webView.getContext();
  }

  @Override
  public boolean execute(final String action, JSONArray data, CallbackContext callbackContext) throws JSONException {

    if (action.equals("setPublishableKey")) {
      setPublishableKey(data.getString(0), callbackContext);
    } else if (action.equals("createAccountToken")) {
      createAccountToken(data.getJSONObject(0), callbackContext);
    } else if (action.equals("createBankAccountToken")) {
      createBankAccountToken(data.getJSONObject(0), callbackContext);
    } else {
      return false;
    }

    return true;

  }

  private JSONObject jsonifyToken(final Token token) {
    try {
      JSONObject tokenObject = new JSONObject();
      tokenObject.put("id", token.getId());
      tokenObject.put("created", token.getCreated());
      tokenObject.put("live_mode", token.getLivemode());
      tokenObject.put("type", token.getType());
      tokenObject.put("used", token.getUsed());

      return tokenObject;

    } catch (JSONException e) {
      return null;
    }
  }

  private void setPublishableKey(final String key, final CallbackContext callbackContext) {

    try {
      stripeInstance = new Stripe(webViewContext, key);
      callbackContext.success();
    } catch (Exception e) {
      callbackContext.error(e.getLocalizedMessage());
    }

  }

  private void createAccountToken(final JSONObject data, final CallbackContext callbackContext) {
    try {

      JSONObject individual = data.getJSONObject("individual");
      Address address = Address.fromJson(individual.getJSONObject("address"));
      JSONObject dob = individual.getJSONObject("dob");
      DateOfBirth dateOfBirth = new DateOfBirth(dob.getInt("day"), dob.getInt("month"), dob.getInt("year"));
      AccountParams.BusinessTypeParams.Individual.Builder individualParams = new AccountParams.BusinessTypeParams.Individual.Builder();

      individualParams.setEmail(individual.getString("email"));
      individualParams.setFirstName(individual.getString("first_name"));
      individualParams.setLastName(individual.getString("last_name"));
      individualParams.setPhone(individual.getString("phone"));
      individualParams.setGender(individual.getString("gender"));
      individualParams.setSsnLast4(individual.getString("ssn_last_4"));
      individualParams.setAddress(address);
      individualParams.setDateOfBirth(dateOfBirth);

      AccountParams accountParams = AccountParams.create(true, individualParams.build());

      stripeInstance.createAccountToken(accountParams, new ApiResultCallback<Token>() {
        public void onSuccess(Token token) {
          callbackContext.success(jsonifyToken(token));
        }

        public void onError(Exception error) {
          callbackContext.error(error.getLocalizedMessage());
        }
      });
    } catch (JSONException e) {
      callbackContext.error(e.getLocalizedMessage());
    }
  }

  private void createBankAccountToken(final JSONObject bankAccount, final CallbackContext callbackContext) {

    try {
      BankAccountTokenParams bankAccountTokenParams = new BankAccountTokenParams(bankAccount.getString("country"),
          bankAccount.getString("currency"), bankAccount.getString("account_number"),
          BankAccountTokenParams.Type.Individual, bankAccount.getString("account_holder_name"),
          bankAccount.getString("routing_number"));

      stripeInstance.createBankAccountToken(bankAccountTokenParams, new ApiResultCallback<Token>() {
        public void onSuccess(Token token) {
          callbackContext.success(jsonifyToken(token));
        }

        public void onError(Exception error) {
          callbackContext.error(error.getLocalizedMessage());
        }
      });

    } catch (JSONException e) {
      callbackContext.error(e.getLocalizedMessage());
    }

  }
}
