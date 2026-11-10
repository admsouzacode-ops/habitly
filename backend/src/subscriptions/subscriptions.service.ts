import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from '../entities/subscription.entity';
import { User } from '../entities/user.entity';
import { google } from 'googleapis';
import { VerifySubscriptionDto } from './dto/subscription.dto';

@Injectable()
export class SubscriptionsService {
  private androidPublisher: any;

  constructor(
    @InjectRepository(Subscription) private subRepo: Repository<Subscription>,
    @InjectRepository(User) private userRepo: Repository<User>,
  ) {
    // Inicializa o cliente Google (credenciais via env ou arquivo)
    const auth = new google.auth.GoogleAuth({
      keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_PATH, // ou credentials: JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON)
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    this.androidPublisher = google.androidpublisher({ version: 'v3', auth });
  }

  async verifyGoogle(userId: string, dto: VerifySubscriptionDto) {
    const packageName = process.env.GOOGLE_PACKAGE_NAME;
    if (!packageName) throw new BadRequestException('GOOGLE_PACKAGE_NAME não configurado');

    try {
      const res = await this.androidPublisher.purchases.subscriptionsv2.get({
        packageName,
        token: dto.purchaseToken,
      });

      const data = res.data;
      const lineItem = data.lineItems?.[0];
      if (!lineItem) throw new BadRequestException('Assinatura inválida');

      const expiryTime = lineItem.expiryTime;
      const isActive = expiryTime && new Date(expiryTime) > new Date();

      // Salva ou atualiza a assinatura
      let sub = await this.subRepo.findOne({ where: { user_id: userId, platform: 'google', purchase_token: dto.purchaseToken } });
      if (!sub) {
        sub = this.subRepo.create({
          user_id: userId,
          platform: 'google',
          purchase_token: dto.purchaseToken,
          product_id: dto.productId,
          status: isActive ? 'active' : 'expired',
          expires_at: expiryTime ? new Date(expiryTime) : null,
          raw_data: data,
        });
      } else {
        sub.status = isActive ? 'active' : 'expired';
        sub.expires_at = expiryTime ? new Date(expiryTime) : null;
        sub.raw_data = data;
      }
      await this.subRepo.save(sub);

      // Atualiza status do usuário
      await this.userRepo.update(userId, {
        is_premium: isActive,
        premium_expires_at: isActive ? new Date(expiryTime) : null,
      });

      return {
        success: true,
        is_premium: isActive,
        expires_at: expiryTime,
        status: sub.status,
      };
    } catch (error) {
      console.error('Google Play verification error:', error.message);
      throw new BadRequestException('Falha ao verificar assinatura com o Google Play');
    }
  }
}
