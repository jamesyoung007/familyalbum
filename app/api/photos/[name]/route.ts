import { getServerSession } from "next-auth";
import { NextResponse } from "next/server";
import { authOptions } from "@/lib/auth";
import { deletePhoto } from "@/lib/photos";

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ name: string }> }
) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.email) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { name } = await params;
  await deletePhoto(decodeURIComponent(name));
  return NextResponse.json({ ok: true });
}
