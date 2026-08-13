export function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'FATAL: JWT_SECRET environment variable must be configured in production',
      );
    }
    return 'super-secret-jwt-key-hr-app-demo-phase-22-minimum-32-chars';
  }
  if (secret.length < 32 && process.env.NODE_ENV === 'production') {
    throw new Error(
      'FATAL: JWT_SECRET must be at least 32 characters long in production',
    );
  }
  return secret;
}
