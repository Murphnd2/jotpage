package com.jotpage.servlet;

import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeRequestUrl;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.Arrays;

public class LoginServlet extends HttpServlet {

    private static final String SCOPES = "openid email profile";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        ServletContext ctx = getServletContext();
        String clientId = ctx.getInitParameter("google.clientId");
        String redirectUri = ctx.getInitParameter("google.redirectUri");

        // Diagnostic: the redirect_uri we send here must match both the
        // Google Cloud Console entry AND the value OAuthCallbackServlet
        // sends during the token exchange. Brackets make whitespace
        // visible; length catches invisible trailing characters.
        log("[login] clientId=" + clientId
                + " redirectUri=[" + redirectUri + "]"
                + " length=" + (redirectUri == null ? -1 : redirectUri.length()));

        String authUrl = new GoogleAuthorizationCodeRequestUrl(
                clientId,
                redirectUri,
                Arrays.asList(SCOPES.split(" ")))
                .setResponseTypes(java.util.Collections.singletonList("code"))
                .set("access_type", "online")
                .set("prompt", "select_account")
                .build();

        resp.sendRedirect(authUrl);
    }
}
