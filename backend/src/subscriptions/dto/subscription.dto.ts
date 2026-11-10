import { IsString, IsNotEmpty } from 'class-validator';

export class VerifySubscriptionDto {
  @IsString()
  @IsNotEmpty()
  purchaseToken: string;

  @IsString()
  @IsNotEmpty()
  productId: string;
}
