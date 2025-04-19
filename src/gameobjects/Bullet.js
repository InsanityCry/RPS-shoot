import { GameObjects, Math } from "phaser";

export class Bullet extends GameObjects.Image
{
    speed;
    end_direction = new Math.Vector2(0, 0);

    constructor(scene, x, y) {
        super(scene, x, y, "bullet");
        this.speed = Phaser.Math.GetSpeed(450, 1);
        // Removed bloom effect
        // Default bullet (player bullet)
        this.name = "bullet";
    }

    fire (x, y, targetX = 1, targetY = 0, bullet_texture = "bullet")
    {
        // Change bullet change texture
        this.setTexture(bullet_texture);

        this.setPosition(x, y);
        this.setActive(true);
        this.setVisible(true);

        // Calculate direction towards target
        if (targetX === 1 && targetY === 0) {
            this.end_direction.setTo(1, 0);
        } else {
            this.end_direction.setTo(targetX - x, targetY - y).normalize();            
        }
    }

    destroyBullet ()
    {
        // Simplified bullet destruction - no flame particles
        this.setActive(false);
        this.setVisible(false);
        this.destroy();
    }

    // Update bullet position and destroy if it goes off screen
    update (time, delta)
    {
        this.x += this.end_direction.x * this.speed * delta;
        this.y += this.end_direction.y * this.speed * delta;

        // Verifica si la bala ha salido de la pantalla
        if (this.x > this.scene.sys.canvas.width || this.x < 0 || this.y > this.scene.sys.canvas.height || this.y < 0) {
            this.setActive(false);
            this.setVisible(false);
            this.destroy();
        }
    }
}