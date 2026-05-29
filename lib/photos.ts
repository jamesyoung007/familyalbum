import {
  BlobSASPermissions,
  BlobServiceClient,
  type ContainerClient
} from "@azure/storage-blob";

const MAX_UPLOAD_BYTES = 20 * 1024 * 1024;

function getContainerClient(): ContainerClient {
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
  const containerName = process.env.AZURE_STORAGE_CONTAINER ?? "family-photos";

  if (!connectionString) {
    throw new Error("AZURE_STORAGE_CONNECTION_STRING is not configured.");
  }

  const service = BlobServiceClient.fromConnectionString(connectionString);
  return service.getContainerClient(containerName);
}

export type Photo = {
  name: string;
  url: string;
  uploadedAt: string;
};

export async function listPhotos(): Promise<Photo[]> {
  const container = getContainerClient();
  await container.createIfNotExists();

  const photos: Photo[] = [];
  for await (const blob of container.listBlobsFlat()) {
    const client = container.getBlobClient(blob.name);
    const url = await client.generateSasUrl({
      expiresOn: new Date(Date.now() + 1000 * 60 * 15),
      permissions: BlobSASPermissions.parse("r")
    });

    photos.push({
      name: blob.name,
      url,
      uploadedAt: blob.properties.createdOn?.toISOString() ?? ""
    });
  }

  return photos.sort((a, b) => b.name.localeCompare(a.name));
}

export async function uploadPhoto(file: File, uploaderEmail: string) {
  if (!file.type.startsWith("image/")) {
    throw new Error("Only image files can be uploaded.");
  }

  if (file.size > MAX_UPLOAD_BYTES) {
    throw new Error("Please upload an image smaller than 20 MB.");
  }

  const container = getContainerClient();
  await container.createIfNotExists();

  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "-").toLowerCase();
  const blobName = `${Date.now()}-${safeName}`;
  const client = container.getBlockBlobClient(blobName);
  const buffer = Buffer.from(await file.arrayBuffer());

  await client.uploadData(buffer, {
    blobHTTPHeaders: {
      blobContentType: file.type
    },
    metadata: {
      uploader: uploaderEmail
    }
  });

  return blobName;
}

export async function deletePhoto(name: string) {
  const container = getContainerClient();
  await container.deleteBlob(name);
}
