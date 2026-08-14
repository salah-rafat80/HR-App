export function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error(
      'FATAL CONFIGURATION ERROR: JWT_SECRET environment variable is missing.',
    );
  }
  if (secret.length < 32) {
    throw new Error(
      'FATAL CONFIGURATION ERROR: JWT_SECRET must be at least 32 characters long.',
    );
  }
  return secret;
}

export function getJwtRefreshSecret(): string | undefined {
  const secret = process.env.JWT_REFRESH_SECRET;
  if (!secret) {
    return undefined;
  }
  if (secret.length < 32) {
    throw new Error(
      'FATAL CONFIGURATION ERROR: JWT_REFRESH_SECRET must be at least 32 characters long when configured.',
    );
  }
  return secret;
}
