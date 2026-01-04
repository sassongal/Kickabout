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

    // Only process profile_photos, hub images, and game photos
    if (!filePath.includes('profile_photos') &&
      !filePath.includes('hub_photos') &&
      !filePath.includes('hub_images') &&
      !filePath.includes('game_photos')) {
      info(`File ${filePath} is not a profile, hub, or game image, skipping resize.`);
      return;
    }

    // Skip if already optimized (contains any optimization suffix)
    if (filePath.includes('_resized') ||
        filePath.includes('_thumb') ||
        filePath.includes('_medium') ||
        filePath.includes('_large')) {
      info(`File ${filePath} is already optimized, skipping.`);
      return;
    }

    if (!sharp) {
      info('Sharp not available, skipping image resize.');
      return;
    }

    info(`Processing image optimization for ${filePath}`);

    try {
      const file = bucket.file(filePath);
      const [fileBuffer] = await file.download();

      // Create multiple optimized versions
      const sizes = [
        { suffix: '_thumb', width: 150, height: 150, quality: 80 }, // Thumbnails (lists, cards)
        { suffix: '_medium', width: 500, height: 500, quality: 85 }, // Medium (detail views)
        { suffix: '_large', width: 1200, height: 1200, quality: 90 }, // Large (full screen)
      ];

      // Process all sizes in parallel
      await Promise.all(sizes.map(async ({ suffix, width, height, quality }) => {
        const optimizedBuffer = await sharp(fileBuffer)
          .resize(width, height, {
            fit: 'cover',
            position: 'center',
          })
          .jpeg({ quality }) // Convert to JPEG with specified quality
          .toBuffer();

        // Upload optimized image with suffix
        const optimizedPath = filePath.replace(/\.[^/.]+$/, `${suffix}.jpg`);
        const optimizedFile = bucket.file(optimizedPath);

        await optimizedFile.save(optimizedBuffer, {
          metadata: {
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=31536000', // 1 year cache
          },
        });

        info(`Optimized image (${width}x${height}) saved to ${optimizedPath}`);
      }));

      // Keep backward compatibility: also create _resized version (same as _medium)
      const resizedBuffer = await sharp(fileBuffer)
        .resize(500, 500, {
          fit: 'cover',
          position: 'center',
        })
        .jpeg({ quality: 85 })
        .toBuffer();

      const resizedPath = filePath.replace(/\.[^/.]+$/, '_resized.jpg');
      const resizedFile = bucket.file(resizedPath);

      await resizedFile.save(resizedBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        },
      });

      info(`Legacy _resized version saved to ${resizedPath}`);
      info(`✅ Image optimization complete for ${filePath}: 4 versions created`);
    } catch (error) {
      info(`Error optimizing image ${filePath}:`, error);
      // Don't throw - we don't want to fail the upload
    }
  },
);

