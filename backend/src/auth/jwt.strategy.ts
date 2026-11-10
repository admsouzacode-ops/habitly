import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'habitly-secret-key-change-in-production',
    });
  }

  async validate(payload: any) {
    const user = await this.userRepo.findOne({ where: { id: payload.sub } });
    if (!user) return null;
    return {
      id: user.id,
      email: user.email,
      is_premium: user.is_premium,
    };
  }
}
