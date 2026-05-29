import type { NextAuthOptions } from "next-auth";
import GoogleProvider from "next-auth/providers/google";

function allowedEmails() {
  return new Set(
    (process.env.ALLOWED_EMAILS ?? "")
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean)
  );
}

export const authOptions: NextAuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID ?? "",
      clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? ""
    })
  ],
  callbacks: {
    async signIn({ user }) {
      const email = user.email?.toLowerCase();
      return Boolean(email && allowedEmails().has(email));
    },
    async session({ session }) {
      return session;
    }
  },
  pages: {
    signIn: "/"
  }
};
