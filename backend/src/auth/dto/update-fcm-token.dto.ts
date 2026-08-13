import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsNotEmpty({ message: 'FCM token is required' })
  @IsString({ message: 'FCM token must be a string' })
  @MaxLength(500, { message: 'FCM token exceeds maximum length' })
  fcmToken!: string;
}
