package com.jotpage.servlet;

import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeTokenRequest;
import com.google.api.client.googleapis.auth.oauth2.GoogleTokenResponse;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.oauth2.Oauth2;
import com.google.api.services.oauth2.model.Userinfo;
import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;

import com.jotpage.dao.UserDao;
import com.jotpage.model.User;
import com.jotpage.util.AppConfig;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

public class OAuthCallbackServlet extends HttpServlet {

    private static final String APPLICATION_NAME = "JotPage";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String code = req.getParameter("code");
        String error = req.getParameter("error");

        if (error != null) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp?error=" + error);
            return;
        }
        if (code == null || code.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp?error=missing_code");
            return;
        }

        String clientId = AppConfig.get("google.clientId");
        String clientSecret = AppConfig.get("google.clientSecret");
        String redirectUri = AppConfig.get("google.redirectUri");

        log("[oauth-cb] clientId=" + clientId
                + " redirectUri=[" + redirectUri + "]"
                + " length=" + (redirectUri == null ? -1 : redirectUri.length()));

        NetHttpTransport transport = new NetHttpTransport();
        GsonFactory jsonFactory = GsonFactory.getDefaultInstance();

        try {
            GoogleTokenResponse tokenResponse = new GoogleAuthorizationCodeTokenRequest(
                    transport,
                    jsonFactory,
                    clientId,
                    clientSecret,
                    code,
                    redirectUri)
                    .execute();

            GoogleCredential credential = new GoogleCredential.Builder()
                    .setTransport(transport)
                    .setJsonFactory(jsonFactory)
                    .setClientSecrets(clientId, clientSecret)
                    .build()
                    .setAccessToken(tokenResponse.getAccessToken())
                    .setRefreshToken(tokenResponse.getRefreshToken());

            Oauth2 oauth2 = new Oauth2.Builder(transport, jsonFactory, credential)
                    .setApplicationName(APPLICATION_NAME)
                    .build();

            Userinfo userinfo = oauth2.userinfo().get().execute();

            String googleId = userinfo.getId();
            String email = userinfo.getEmail();
            String displayName = userinfo.getName();
            String avatarUrl = userinfo.getPicture();

            UserDao userDao = new UserDao();
            User user = userDao.createOrUpdate(googleId, email, displayName, avatarUrl);

            HttpSession session = req.getSession(true);
            session.setAttribute("user", user);

            resp.sendRedirect(req.getContextPath() + "/app/dashboard");
        } catch (SQLException e) {
            throw new ServletException("Failed to persist user", e);
        } catch (IOException e) {
            throw new ServletException("Failed to exchange OAuth code", e);
        }
    }
}
