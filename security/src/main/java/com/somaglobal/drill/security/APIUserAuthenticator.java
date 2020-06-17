package com.somaglobal.drill.security;     

   import org.apache.drill.common.config.DrillConfig;
   import org.apache.drill.exec.exception.DrillbitStartupException;
   import org.apache.drill.exec.rpc.user.security.UserAuthenticator;
   import org.apache.drill.exec.rpc.user.security.UserAuthenticationException;
   import org.apache.drill.exec.rpc.user.security.UserAuthenticatorTemplate;

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
      // If the authenticator has any setup such as making sure authenticator provider servers are up and running or 
      // needed libraries are available, it should be added here.
    }

   /**
   * Authenticate the given <i>user</i> and <i>password</i> combination.
   *
   * @param userName
   * @param password
   * @throws UserAuthenticationException if authentication fails for given user and password.
   */
    @Override
    public void authenticate(String userName, String password) throws UserAuthenticationException {
      if (!(password.equals(userName))) {
    throw new UserAuthenticationException("For demostration purposes, please use same password as username");
      }
    }

   /**
   * Close the authenticator. Used to release resources. Ex. LDAP authenticator opens connections to LDAP server,
   * such connections resources are released in a safe manner as part of close.
   *
   * @throws IOException
   */
    @Override
    public void close() throws IOException {
      // Any clean up such as releasing files/network resources should be done here
    }
   }  