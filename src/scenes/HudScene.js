import { Scene } from "phaser";

// The HUD scene is the scene that shows the points and the remaining time.
export class HudScene extends Scene {
    
    points_text;

    constructor() {
        super("HudScene");
    }

    init(data) {
        this.cameras.main.fadeIn(1000, 0, 0, 0);
    }

    create() {
        this.points_text = this.add.bitmapText(10, 10, "pixelfont", "POINTS:0000", 24);
    }

    update_points(points) {
        this.points_text.setText(`POINTS:${points.toString().padStart(4, "0")}`);
    }
}