import { GameObjects, Physics } from "phaser";
import { Bullet } from "./Bullet";

export class Player extends Physics.Arcade.Image {
    
    // Player states: waiting, start, can_move
    state = "waiting";
    scene = null;
    bullets = null;

    constructor({scene}) {
        super(scene, scene.scale.width / 2, scene.scale.height - 100, "player");
        this.scene = scene;
        this.scene.add.existing(this);
        this.scene.physics.add.existing(this);
        
        // Add gravity to the player so it stays on the ground
        this.setGravityY(300);

        // Bullets group to create pool
        this.bullets = this.scene.physics.add.group({
            classType: Bullet,
            maxSize: 100,
            runChildUpdate: true
        });
    }

    start() {
        this.state = "can_move";
    }

    move(direction) {
        if(this.state === "can_move") {
            if (direction === "left" && this.x - 10 > 0) {
                this.x -= 5;
            } else if (direction === "right" && this.x + 75 < this.scene.scale.width) {
                this.x += 5;
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
        // Sinusoidal movement up and down up and down 2px
        this.y += Math.sin(this.scene.time.now / 200) * 0.10;
    }

}