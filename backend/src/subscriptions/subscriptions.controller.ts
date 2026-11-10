import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SubscriptionsService } from './subscriptions.service';
import { VerifySubscriptionDto } from './dto/subscription.dto';

@Controller('subscriptions')
@UseGuards(AuthGuard('jwt'))
export class SubscriptionsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Post('verify/google')
  verifyGoogle(@Request() req, @Body() dto: VerifySubscriptionDto) {
    return this.subscriptionsService.verifyGoogle(req.user.id, dto);
  }
}
