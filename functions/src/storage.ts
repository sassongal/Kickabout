import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Generates a v4 signed URL for uploading a hub photo.
 *
 * This function ensures that only hub managers can get a URL to upload photos,
 * securing the Firebase Storage bucket. The client receives this URL and uses
 * it to upload the file directly to Cloud Storage.
 *
 * @param {object} data The data passed to the function from the client.
 * @param {string} data.hubId The ID of the hub to which the photo will be uploaded.
 * @param {string} data.fileName The name of the file to be uploaded (e.g., 'logo.jpg').
 * @param {string} data.contentType The MIME type of the file (e.g., 'image/jpeg').
 * @param {functions.https.CallableContext} context The context of the function call,
 * containing authentication information.
 *
 * @returns {Promise<{url: string}>} A promise that resolves with the signed URL.
 * @throws {functions.https.HttpsError} Throws an error if the user is not authenticated,
 * lacks permissions, or if arguments are invalid.
 */
export const getHubPhotoUploadUrl = functions
    .region("us-central1") // Specify region for consistency
    .https.onCall(async (data, context) => {
        // 1. Authentication Check: Ensure the user is logged in.
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated."
            );
        }

        // 2. Input Validation: Ensure all required parameters are provided.
        const { hubId, fileName, contentType } = data;
        if (typeof hubId !== "string" || typeof fileName !== "string" || typeof contentType !== "string") {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "The function requires 'hubId', 'fileName', and 'contentType' arguments."
            );
        }
        const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
        if (!allowedTypes.includes(contentType)) {
            throw new functions.https.HttpsError("invalid-argument", "Only image uploads are allowed.");
        }
        if (!/^[\\w.-]{1,100}$/.test(fileName)) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid file name.");
        }

        const uid = context.auth.uid;

        // 3. Permission Check: Verify the user is a manager of the specified hub.
        try {
            const hubDoc = await admin.firestore().doc(`hubs/${hubId}`).get();
            if (!hubDoc.exists) {
                throw new functions.https.HttpsError("not-found", "The specified hub does not exist.");
            }

            const isCreator = hubDoc.data()?.createdBy === uid;
            let isManager = isCreator;

            // If not the creator, check the members subcollection for the 'manager' role.
            if (!isManager) {
                const memberDoc = await admin.firestore().doc(`hubs/${hubId}/members/${uid}`).get();
                isManager = memberDoc.exists && memberDoc.data()?.role === "manager" && memberDoc.data()?.status === "active";
            }

            if (!isManager) {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "You must be a manager of this hub to upload photos."
                );
            }
        } catch (error) {
            if (error instanceof functions.https.HttpsError) throw error;
            console.error(`Permission check failed for user ${uid} on hub ${hubId}:`, error);
            throw new functions.https.HttpsError("internal", "An error occurred while verifying permissions.");
        }

        // 4. Generate Signed URL: If permissions are valid, create the upload URL.
        const bucket = admin.storage().bucket();
        const filePath = `hub_photos/${hubId}/${fileName}`;
        const file = bucket.file(filePath);

        const options = {
            version: "v4" as const,
            action: "write" as const,
            expires: Date.now() + 15 * 60 * 1000, // URL is valid for 15 minutes
            contentType: contentType,
        };

        try {
            const [url] = await file.getSignedUrl(options);
            console.log(`Generated signed URL for ${filePath} for user ${uid}.`);
            return { url };
        } catch (error) {
            console.error(`Failed to generate signed URL for ${filePath}:`, error);
            throw new functions.https.HttpsError("internal", "Could not generate the upload URL.");
        }
    });

/**
 * Generates a v4 signed URL for uploading a game photo.
 *
 * Only authenticated users who are the game creator or have a signup record
 * for the game can obtain an upload URL.
 */
export const getGamePhotoUploadUrl = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated."
            );
        }

        const { gameId, fileName, contentType } = data;
        if (typeof gameId !== "string" || typeof fileName !== "string" || typeof contentType !== "string") {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "The function requires 'gameId', 'fileName', and 'contentType' arguments."
            );
        }
        const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
        if (!allowedTypes.includes(contentType)) {
            throw new functions.https.HttpsError("invalid-argument", "Only image uploads are allowed.");
        }
        if (!/^[\\w.-]{1,100}$/.test(fileName)) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid file name.");
        }

        const uid = context.auth.uid;

        // Permission check: game creator or participant (has signup doc)
        try {
            const gameRef = admin.firestore().doc(`games/${gameId}`);
            const gameDoc = await gameRef.get();
            if (!gameDoc.exists) {
                throw new functions.https.HttpsError("not-found", "The specified game does not exist.");
            }

            const isCreator = gameDoc.data()?.createdBy === uid;

            let isParticipant = false;
            if (!isCreator) {
                const signupDoc = await gameRef.collection("signups").doc(uid).get();
                isParticipant = signupDoc.exists;
            }

            if (!isCreator && !isParticipant) {
                throw new functions.https.HttpsError(
                    "permission-denied",
                    "Only the game creator or participants can upload photos."
                );
            }
        } catch (error) {
            if (error instanceof functions.https.HttpsError) throw error;
            console.error(`Permission check failed for user ${uid} on game ${gameId}:`, error);
            throw new functions.https.HttpsError("internal", "An error occurred while verifying permissions.");
        }

        const bucket = admin.storage().bucket();
        const filePath = `game_photos/${gameId}/${fileName}`;
        const file = bucket.file(filePath);

        const options = {
            version: "v4" as const,
            action: "write" as const,
            expires: Date.now() + 15 * 60 * 1000,
            contentType: contentType,
        };

        try {
            const [url] = await file.getSignedUrl(options);
            console.log(`Generated game photo signed URL for ${filePath} for user ${uid}.`);
            return { url };
        } catch (error) {
            console.error(`Failed to generate signed URL for ${filePath}:`, error);
            throw new functions.https.HttpsError("internal", "Could not generate the upload URL.");
        }
    });
