import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { IS_PUBLIC_KEY } from './public.decorator';
import { ApiKeyService } from '../api-key/api-key.service';
import { SupabaseService } from '../supabase/supabase.service';

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
  user?: AuthenticatedUser;
}

const SERVICE_TOKEN_HEADER = 'x-service-token';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private apiKeyService: ApiKeyService,
    private supabase: SupabaseService,
  ) {}

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

    const match = /^Bearer (.+)$/.exec(request.headers.authorization ?? '');
    if (!match) {
      throw new UnauthorizedException('Invalid or missing access token');
    }

    // Verifies the Supabase-issued JWT (locally against the project's JWKS
    // for asymmetric keys, via the Auth server otherwise) and checks expiry.
    const { data, error } = await this.supabase.admin.auth.getClaims(match[1]);
    if (error || !data) {
      throw new UnauthorizedException('Invalid or missing access token');
    }

    const claims = data.claims as SupabaseClaims;
    request.user = {
      id: claims.sub,
      email: claims.email ?? '',
      // app_metadata is only writable server-side, so the role can be trusted.
      role: claims.app_metadata?.role ?? 'basic',
      firstname: claims.user_metadata?.firstName,
      lastname: claims.user_metadata?.lastName,
    };
    return true;
  }
}

interface SupabaseClaims {
  sub: string;
  email?: string;
  app_metadata?: { role?: string };
  user_metadata?: { firstName?: string; lastName?: string };
}
