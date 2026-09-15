import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';
import { UserRole } from '../user/entities/user.entity';
import type {
  AuthenticatedUser,
  ServiceAuthenticatedRequest,
} from './jwt-auth.guard';

interface RequestWithUser extends ServiceAuthenticatedRequest {
  user?: AuthenticatedUser;
}

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<RequestWithUser>();

    // A trusted service (validated in JwtAuthGuard) bypasses role checks
    // entirely — the service token itself is the authorization boundary.
    if (request.isServiceRequest) {
      return true;
    }

    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const { user } = request;

    if (!user || !requiredRoles.includes(user.role as UserRole)) {
      throw new ForbiddenException(
        'You do not have permission to access this resource',
      );
    }

    return true;
  }
}
