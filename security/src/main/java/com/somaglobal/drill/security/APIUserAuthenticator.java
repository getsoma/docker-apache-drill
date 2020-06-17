package com.somaglobal.drill.security;

import org.apache.drill.common.config.DrillConfig;
import org.apache.drill.exec.exception.DrillbitStartupException;
import org.apache.drill.exec.rpc.user.security.UserAuthenticator;
import org.apache.drill.exec.rpc.user.security.UserAuthenticationException;
import org.apache.drill.exec.rpc.user.security.UserAuthenticatorTemplate;

import org.apache.http.client.CredentialsProvider;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.auth.AuthScope;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;

import org.apache.http.HttpEntity;
import org.apache.http.util.EntityUtils;

import java.io.IOException;

/*
* Implement {@link org.apache.drill.exec.rpc.user.security.UserAuthenticator} for illustrating how to develop a custom authenticator and use it in Drill
*/
@UserAuthenticatorTemplate(type = "myCustomAuthenticatorType")
public class APIUserAuthenticator implements UserAuthenticator {

  /**
   * Setup for authenticating user credentials.
   */
  @Override
  public void setup(DrillConfig drillConfig) throws DrillbitStartupException {
    // If the authenticator has any setup such as making sure authenticator provider
    // servers are up and running or
    // needed libraries are available, it should be added here.
  }

  /**
   * Authenticate the given <i>user</i> and <i>password</i> combination.
   *
   * @param userName
   * @param password
   * @throws UserAuthenticationException if authentication fails for given user
   *                                     and password.
   */
  @Override
  public void authenticate(String userName, String password) throws UserAuthenticationException {
    CredentialsProvider provider = new BasicCredentialsProvider();
    UsernamePasswordCredentials credentials = new UsernamePasswordCredentials(userName, password);
    provider.setCredentials(AuthScope.ANY, credentials);

    HttpClient client = HttpClientBuilder.create().setDefaultCredentialsProvider(provider).build();

    try {
      HttpResponse response = client.execute(new HttpGet("http://app:5000/api/user/current"));
      int statusCode = response.getStatusLine().getStatusCode();

      if (HttpStatus.SC_OK != statusCode) {
        throw new UserAuthenticationException(response.getStatusLine().getReasonPhrase());
      }

      HttpEntity entity = response.getEntity();
      String content = EntityUtils.toString(entity);
      if (!content.contains("\"APIUser\":true")) {
        throw new UserAuthenticationException("Non-API users cannot access drillbit");
      }
    } catch (IOException ex) {
      throw new UserAuthenticationException(ex.getMessage());
    }
  }

  /**
   * Close the authenticator. Used to release resources. Ex. LDAP authenticator
   * opens connections to LDAP server, such connections resources are released in
   * a safe manner as part of close.
   *
   * @throws IOException
   */
  @Override
  public void close() throws IOException {
    // Any clean up such as releasing files/network resources should be done here
  }
}