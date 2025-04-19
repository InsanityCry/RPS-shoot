import { GameObjects, Physics } from "phaser";
import { Bullet } from "./Bullet";

export class Player extends Physics.Arcade.Image {
    
    // Player states: waiting, start, can_move
    state = "waiting";
    scene = null;
    bullets = null;
    moveSpeed = 200;

    constructor({scene}) {
        super(scene, scene.scale.width / 2, scene.scale.height - 100, "player");
        this.scene = scene;
        this.scene.add.existing(this);
        this.scene.physics.add.existing(this);
        
        // Configure physics body
        this.setGravityY(300);
        this.setCollideWorldBounds(true);
        this.setBounce(0);
        this.body.setDrag(300, 0);

        // Bullets group to create pool
        this.bullets = this.scene.physics.add.group({
            classType: Bullet,
            maxSize: 100,
            runChildUpdate: true
        });
    }

    start() {
        this.state = "can_move";
        // Enable fixed step physics to reduce movement lag
        this.scene.physics.world.fixedStep = true;
    }

    move(direction) {
        if(this.state === "can_move") {
            if (direction === "left" && this.x - 10 > 0) {
                this.setVelocityX(-this.moveSpeed);
            } else if (direction === "right" && this.x + 75 < this.scene.scale.width) {
                this.setVelocityX(this.moveSpeed);
            } else {
                // Decelerate when no direction is pressed
                this.setVelocityX(0);
            }
        }
    }

    fire(x, y) {
        if (this.state === "can_move") {
            // Create bullet
            const bullet = this.bullets.get();
            if (bullet) {
                bullet.fire(this.x + 16, this.y + 5, x, y);
            }
        }
    }

    update() {
        // The sinusoidal movement is now handled by physics
        // We can add a small vertical oscillation if needed
        if (this.state === "can_move" && this.body.velocity.y === 0) {
            this.y += Math.sin(this.scene.time.now / 200) * 0.10;
        }
    }
}