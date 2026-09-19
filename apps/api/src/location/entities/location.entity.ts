import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import type { Point } from 'geojson';
import { User } from 'src/user/entities/user.entity';

@Entity()
export class Location {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  name!: string;

  @Column()
  state!: string;

  @Column()
  nationalPark!: boolean;

  @Column({ nullable: true })
  nationalParkName!: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'updatedByUserId' })
  updatedByUserId!: User;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;

  // GeoJSON Point, WGS84. Coordinates are [longitude, latitude].
  @Index({ spatial: true })
  @Column({ type: 'geography', spatialFeatureType: 'Point', srid: 4326 })
  coordinates!: Point;

  // Horizontal accuracy in metres, as reported by the device (Geolocation API).
  @Column({ type: 'real', nullable: true })
  accuracyMeters!: number | null;
}
