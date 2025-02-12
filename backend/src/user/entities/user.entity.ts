import {
  BeforeInsert,
  BeforeUpdate,
  Column,
  Entity,
  OneToMany,
  PrimaryColumn,
  PrimaryGeneratedColumn,
} from 'typeorm';
import * as bcrypt from 'bcrypt';
import { Listing } from 'src/listing/entities/listings';

@Entity()
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  password: string;

  @Column()
  username: string;

  @Column({ unique: true, nullable: true })
  email: string;

  @Column('simple-json', { default: JSON.stringify(['recipient']) })
  role: string[];

  @Column({ nullable: true })
  refreshToken: string;

  @Column({ unique: true })
  cnic: string;

  @Column({nullable: true})
  bloodGroup: string;

  @Column({nullable: true})
  phone: string;

  @Column({nullable: true})
  age: number;

  @Column({nullable: true})
  isVerified: boolean;

  @Column({nullable: true})
  isDonor: boolean;

  @Column({nullable: true})
  lastDonationDate: Date;

  @Column({nullable: true})
  credibilityPoints: number;

  @Column({nullable: true})
  city: string;

  @OneToMany(() => Listing, (listing) => listing.user)
  listings: Listing[];
  

//   @Column()
//   country: string;

  @BeforeInsert()
  async hashPassword() {
    this.password = await bcrypt.hash(this.password, 10);
  }

  async isMatch(enteredPassword: string): Promise<boolean> {
    if (enteredPassword) {
      return await bcrypt.compare(enteredPassword, this.password);
    }
    return false;
  }
}
