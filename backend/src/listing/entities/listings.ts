import { User } from "src/user/entities/user.entity";
import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from "typeorm";



@Entity()
export class Listing {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    location: string;

    @Column()
    groupRequired: string;

    // @Column()
    // proofMedia: string;

    @Column()
    bagsRequired: number;

    @Column()
    requiredTill: Date;

    @Column()
    pickAndDrop: boolean;

    @Column({ nullable: true })
    willPay: boolean;


    // Will contain UserId
    @ManyToOne(() => User, (user) => user.listings)
    @JoinColumn({ name: "userId" })
    user: User

    @CreateDateColumn({ type: 'timestamp' })
    createdAt: Date;


    @CreateDateColumn({ type: 'timestamp' })
    updatedAt: Date;

    //   CreatedAt
    // Location 
    // GroupRequired
    // Proof (Media)
    // BagsRequired
    // ValidTill
    // PickAndDrop
    // WillPay?

}
