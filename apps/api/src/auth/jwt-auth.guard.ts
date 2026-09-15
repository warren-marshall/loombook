import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import type { Request } from 'express';
import { IS_PUBLIC_KEY } from './public.decorator';
import { ApiKeyService } from '../api-key/api-key.service';

export interface AuthenticatedUser {
  id: string;
  email: string;
  role: string;
  firstname?: string;
  lastname?: string;
}

// Marks a request that authenticated via service token rather than a human
// JWT. RolesGuard checks this to bypass role checks for trusted services.
export interface ServiceAuthenticatedRequest extends Request {
  isServiceRequest?: boolean;
}

const SERVICE_TOKEN_HEADER = 'x-service-token';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private reflector: Reflector,
    private apiKeyService: ApiKeyService,
  ) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context
      .switchToHttp()
      .getRequest<ServiceAuthenticatedRequest>();

    const serviceToken = request.headers[SERVICE_TOKEN_HEADER];
    if (typeof serviceToken === 'string' && serviceToken.length > 0) {
      const isValid = await this.apiKeyService.validate(serviceToken);
      if (isValid) {
        request.isServiceRequest = true;
        return true;
      }
      // A service-token header was present but invalid — fail explicitly
      // rather than silently falling through to the human JWT check.
      throw new UnauthorizedException('Invalid service token');
    }

    return super.canActivate(context) as Promise<boolean>;
  }

  handleRequest<TUser = AuthenticatedUser>(
    err: Error | null,
    user: TUser | false,
  ): TUser {
    if (err || !user) {
      throw err || new UnauthorizedException('Invalid or missing access token');
    }
    return user;
  }
}
