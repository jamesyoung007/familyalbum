"use client";

import { FormEvent, useEffect, useState } from "react";
import { signIn, signOut, useSession } from "next-auth/react";

type Photo = {
  name: string;
  url: string;
  uploadedAt: string;
};

export function Album() {
  const { data: session, status } = useSession();
  const [photos, setPhotos] = useState<Photo[]>([]);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  async function loadPhotos() {
    const response = await fetch("/api/photos");
    if (!response.ok) {
      setMessage("Could not load photos. Check your Azure storage settings.");
      return;
    }

    const data = (await response.json()) as { photos: Photo[] };
    setPhotos(data.photos);
  }

  useEffect(() => {
    if (status === "authenticated") {
      void loadPhotos();
    }
  }, [status]);

  async function handleUpload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage("");

    const form = event.currentTarget;
    const formData = new FormData(form);
    const response = await fetch("/api/photos", {
      method: "POST",
      body: formData
    });

    setBusy(false);

    if (!response.ok) {
      const data = (await response.json()) as { error?: string };
      setMessage(data.error ?? "Upload failed.");
      return;
    }

    form.reset();
    setMessage("Photo uploaded.");
    await loadPhotos();
  }

  async function removePhoto(name: string) {
    setBusy(true);
    await fetch(`/api/photos/${encodeURIComponent(name)}`, {
      method: "DELETE"
    });
    setBusy(false);
    await loadPhotos();
  }

  return (
    <main className="shell">
      <header className="masthead">
        <section className="brand">
          <p className="kicker">Private family space</p>
          <h1>Family Album</h1>
          <p className="subtitle">
            A quiet place for shared photos, protected by Google sign-in and an
            email allowlist you control.
          </p>
        </section>

        <div className="actions">
          {status === "authenticated" ? (
            <>
              <span className="message">{session.user?.email}</span>
              <button className="button secondary" onClick={() => signOut()}>
                Sign out
              </button>
            </>
          ) : (
            <button className="button" onClick={() => signIn("google")}>
              Sign in with Google
            </button>
          )}
        </div>
      </header>

      {status === "loading" && <p className="empty">Checking your session...</p>}

      {status === "unauthenticated" && (
        <section className="empty">
          Sign in with an allowed Gmail address to view and upload family photos.
        </section>
      )}

      {status === "authenticated" && (
        <>
          <section className="panel">
            <form className="upload" onSubmit={handleUpload}>
              <input
                className="fileInput"
                name="photo"
                type="file"
                accept="image/*"
                required
              />
              <button className="button" disabled={busy} type="submit">
                {busy ? "Working..." : "Upload photo"}
              </button>
            </form>
            {message && <p className="message">{message}</p>}
          </section>

          {photos.length === 0 ? (
            <section className="empty">No photos yet.</section>
          ) : (
            <section className="grid" aria-label="Family photos">
              {photos.map((photo) => (
                <article className="photo" key={photo.name}>
                  <img src={photo.url} alt="Family album upload" />
                  <div className="photoFooter">
                    <span className="photoName" title={photo.name}>
                      {photo.name.replace(/^\d+-/, "")}
                    </span>
                    <button
                      className="textButton"
                      disabled={busy}
                      onClick={() => removePhoto(photo.name)}
                    >
                      Delete
                    </button>
                  </div>
                </article>
              ))}
            </section>
          )}
        </>
      )}
    </main>
  );
}
