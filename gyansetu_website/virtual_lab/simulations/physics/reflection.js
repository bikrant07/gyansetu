import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

class ReflectionSimulation {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(75, this.container.clientWidth / this.container.clientHeight, 0.1, 1000);
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        
        this.init();
        this.createLightSource();
        this.createMirror();
        this.createControls();
        this.animate();
    }

    init() {
        this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
        this.container.appendChild(this.renderer.domElement);
        this.camera.position.z = 5;
        this.scene.background = new THREE.Color(0xf0f0f0);

        // Add ambient light
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
        this.scene.add(ambientLight);
    }

    createLightSource() {
        // Create laser pointer
        const laserGeometry = new THREE.CylinderGeometry(0.1, 0.1, 0.5);
        const laserMaterial = new THREE.MeshPhongMaterial({ color: 0xff0000 });
        this.laser = new THREE.Mesh(laserGeometry, laserMaterial);
        this.scene.add(this.laser);

        // Create light beam
        const beamGeometry = new THREE.BufferGeometry();
        const beamMaterial = new THREE.LineBasicMaterial({ color: 0xff0000 });
        this.incidentBeam = new THREE.Line(beamGeometry, beamMaterial);
        this.reflectedBeam = new THREE.Line(beamGeometry, beamMaterial);
        this.scene.add(this.incidentBeam);
        this.scene.add(this.reflectedBeam);
    }

    createMirror() {
        // Create mirror surface
        const mirrorGeometry = new THREE.PlaneGeometry(2, 2);
        const mirrorMaterial = new THREE.MeshPhongMaterial({ 
            color: 0x808080,
            specular: 0xffffff,
            shininess: 100
        });
        this.mirror = new THREE.Mesh(mirrorGeometry, mirrorMaterial);
        this.scene.add(this.mirror);
    }

    createControls() {
        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
    }

    updateBeams(incidentAngle) {
        // Update incident beam
        const startPoint = new THREE.Vector3(-2, 0, 0);
        const endPoint = new THREE.Vector3(0, 0, 0);
        this.incidentBeam.geometry.setFromPoints([startPoint, endPoint]);

        // Calculate reflection angle
        const reflectionAngle = -incidentAngle;
        const reflectedEnd = new THREE.Vector3(
            2 * Math.cos(reflectionAngle),
            2 * Math.sin(reflectionAngle),
            0
        );
        this.reflectedBeam.geometry.setFromPoints([endPoint, reflectedEnd]);
    }

    animate() {
        requestAnimationFrame(() => this.animate());
        this.controls.update();
        this.renderer.render(this.scene, this.camera);
    }
}

export default ReflectionSimulation; 