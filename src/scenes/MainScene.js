import { Scene } from "phaser";
import { Player } from "../gameobjects/Player";
// import { BlueEnemy } from "../gameobjects/BlueEnemy";

export class MainScene extends Scene {
    player = null;
    // enemy_blue = null;
    cursors = null;
    ground = null;
    wasdKeys = null;

    points = 0;

    constructor() {
        super("MainScene");
    }

    init() {
        this.cameras.main.fadeIn(1000, 0, 0, 0);
        // Don't launch the menu scene anymore
        // this.scene.launch("MenuScene");

        // Reset points
        this.points = 0;
    }

    create() {
        this.add.image(0, 0, "background")
            .setOrigin(0, 0);
        // this.add.image(0, this.scale.height, "floor").setOrigin(0, 1);
        this.ground = this.add.graphics();
        this.ground.fillStyle(0xffffff, 1.0);
        this.ground.fillRect(0, this.scale.height - 50, this.scale.width, 50);

        this.groundBody = this.physics.add.staticBody(0, this.scale.height - 50, this.scale.width, 50)


        // Player
        this.player = new Player({ scene: this });

        // Enemy
        // this.enemy_blue = new BlueEnemy(this);

        // Cursor keys 
        this.cursors = this.input.keyboard.createCursorKeys();
        
        // WASD keys
        this.wasdKeys = {
            up: this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W),
            down: this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S),
            left: this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A),
            right: this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D),
        };
        
        this.cursors.space.on("down", () => {
            this.player.fire();
        });
        this.input.on("pointerdown", (pointer) => {
            this.player.fire(pointer.x, pointer.y);
        });

        // Overlap enemy with bullets
        /* 
        this.physics.add.overlap(this.player.bullets, this.enemy_blue, (enemy, bullet) => {
            bullet.destroyBullet();
            this.enemy_blue.damage(this.player.x, this.player.y);
            this.points += 10;
            this.scene.get("HudScene")
                .update_points(this.points);
        });
        */

        // Overlap player with enemy bullets
        /*
        this.physics.add.overlap(this.enemy_blue.bullets, this.player, (player, bullet) => {
            bullet.destroyBullet();
            this.cameras.main.shake(100, 0.01);
            // Flash the color white for 300ms
            this.cameras.main.flash(300, 255, 10, 10, false,);
            this.points -= 10;
            this.scene.get("HudScene")
                .update_points(this.points);
        });
        */

        // Start the game automatically
        this.scene.launch("HudScene");
        this.player.start();
        // this.enemy_blue.start();
        
        // Keep the event handler for backward compatibility
        this.game.events.on("start-game", () => {
            this.scene.stop("MenuScene");
            this.scene.launch("HudScene");
            this.player.start();
            // this.enemy_blue.start();
        });
        
        this.physics.add.collider(this.player, this.groundBody);
    }

    update() {
        this.player.update();
        // this.enemy_blue.update();

        // Player movement using arrow keys or WASD
        if (this.cursors.left.isDown || this.wasdKeys.left.isDown) {
            this.player.move("left");
        }
        if (this.cursors.right.isDown || this.wasdKeys.right.isDown) {
            this.player.move("right");
        }
    }
}