import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserService } from '../user/user.service';

interface TokenPayload {
  sub: string;
  email: string;
  role: string;
  firstname?: string;
  lastname?: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly userService: UserService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async login(email: string, password: string) {
    const user = await this.userService.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const valid = await this.userService.verifyPassword(
      password,
      user.password,
    );
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.issueTokens({
      sub: user.id,
      email: user.email,
      role: user.userRole,
      firstname: user.firstName,
      lastname: user.lastName,
    });
  }

  refresh(refreshToken: string) {
    try {
      const payload = this.jwtService.verify<TokenPayload>(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      return this.issueTokens({
        sub: payload.sub,
        email: payload.email,
        role: payload.role,
        firstname: payload.firstname,
        lastname: payload.lastname,
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  private issueTokens(payload: TokenPayload) {
    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_ACCESS_SECRET'),
      expiresIn: '15m',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: '24h',
    });

    return { accessToken, refreshToken };
  }
}
