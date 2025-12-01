/* eslint-disable max-len */
const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { info } = require('firebase-functions/logger');
const { storage, sharp } = require('./utils');

exports.onImageUploaded = onObjectFinalized(
  {
    maxInstances: 10,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    const bucket = storage.bucket(event.data.bucket);

    // Only process images
    if (!contentType || !contentType.startsWith('image/')) {
      info(`File ${filePath} is not an image, skipping resize.`);
      return;
    }

    // Only process profile_photos and hub images
    if (!filePath.includes('profile_photos') &&
      !filePath.includes('hub_photos') &&
      !filePath.includes('hub_images')) {
      info(`File ${filePath} is not a profile or hub image, skipping resize.`);
      return;
    }

    // Skip if already resized (contains _resized suffix)
    if (filePath.includes('_resized')) {
      info(`File ${filePath} is already resized, skipping.`);
      return;
    }

    if (!sharp) {
      info('Sharp not available, skipping image resize.');
      return;
    }

    info(`Processing image resize for ${filePath}`);

    try {
      const file = bucket.file(filePath);
      const [fileBuffer] = await file.download();

      // Resize to 500x500px (maintain aspect ratio, crop to fit)
      const resizedBuffer = await sharp(fileBuffer)
        .resize(500, 500, {
          fit: 'cover',
          position: 'center',
        })
        .jpeg({ quality: 85 }) // Convert to JPEG with 85% quality
        .toBuffer();

      // Upload resized image with _resized suffix
      const resizedPath = filePath.replace(/\.[^/.]+$/, '_resized.jpg');
      const resizedFile = bucket.file(resizedPath);

      await resizedFile.save(resizedBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000', // 1 year cache
        },
      });

      info(`Resized image saved to ${resizedPath}`);

      // Optional: Delete original if you want to save storage
      // await file.delete();
      // info(`Deleted original image ${filePath}`);
    } catch (error) {
      info(`Error resizing image ${filePath}:`, error);
      // Don't throw - we don't want to fail the upload
    }
  },
);

