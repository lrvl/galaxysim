#!/bin/bash
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
for cmd in seq awk sort tr bc; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done
COLS=$(tput cols)
LINES=$(tput lines)
PI=3.14159
GROWTH_SPEED=0.01
INITIAL_ROTATION_SPEED=21
MIN_ROTATION_SPEED=2
MAX_SIZE=300
ROTATIONS=30
FADE_STEPS=20
MIN_SIZE=10
GROWTH_STEP=1
NUM_ARMS=2
SLOWDOWN_THRESHOLD=0.1
CENTRAL_MASS=1000000
DARK_MATTER_FRACTION=0.8
STAR_FORMATION_RATE=0.001
CENTRAL_BRIGHTNESS=1.5
DUST_DENSITY=0.2
CLUSTER_CHANCE=0.001
BAR_LENGTH=40
BAR_WIDTH=10
ASYMMETRY_FACTOR=0.1
ARM_TIGHTNESS=0.5

tput civis

draw_spiral() {
    local size=$1
    local angle=$2
    local opacity=${3:-1}
    local growth_factor=$4
    local seed=$5
    
    seq 1 $size | awk -v seed=$seed -v angle=$angle -v cols=$COLS -v lines=$LINES -v pi=$PI -v opacity=$opacity -v num_arms=$NUM_ARMS -v growth_factor=$growth_factor -v central_mass=$CENTRAL_MASS -v dark_matter_fraction=$DARK_MATTER_FRACTION -v star_formation_rate=$STAR_FORMATION_RATE -v central_brightness=$CENTRAL_BRIGHTNESS -v dust_density=$DUST_DENSITY -v cluster_chance=$CLUSTER_CHANCE -v bar_length=$BAR_LENGTH -v bar_width=$BAR_WIDTH -v asymmetry_factor=$ASYMMETRY_FACTOR -v arm_tightness=$ARM_TIGHTNESS '
    BEGIN {
        srand(seed);
    }
    function keplerian_velocity(r) {
        return sqrt(central_mass / r);
    }
    function dark_matter_velocity(r) {
        return sqrt((central_mass + dark_matter_fraction * central_mass * (r / 20)) / r);
    }
    {
        for (arm = 0; arm < num_arms; arm++) {
            t = $1 / 20 * pi;
            base_r = t * (1 + sin(t/2) * 0.3);
            arm_length = 1 + sin(arm * pi / num_arms) * 0.2 + (rand() - 0.5) * asymmetry_factor;
            r = base_r * arm_length;
            
            v_kep = keplerian_velocity(r);
            v_dm = dark_matter_velocity(r);
            rotation_factor = (v_dm / v_kep) * 0.5;
            
            for (i = -2; i <= 2; i++) {
                for (j = -1; j <= 1; j++) {
                    a = t * arm_tightness + angle * pi / 180 + (arm * 2 * pi / num_arms) * rotation_factor;
                    x = int(cols/2 + (r + i) * cos(a + j * 0.05));
                    y = int(lines/2 + (r + i) * sin(a + j * 0.05)/2.5);
                    
                    if (x > 0 && x <= cols && y > 0 && y <= lines) {
                        density = 0.1 - (i*i + j*j) * 0.01;
                        if (r < bar_length / 2) {
                            density *= 1.5;  # Increased density in the bar
                        }
                        if (density < 0) density = 0;
                        if (rand() < density) {
                            distance_from_center = sqrt((x - cols/2)^2 + (y - lines/2)^2);
                            center_intensity = (1 - distance_from_center / (cols/4)) * growth_factor;
                            if (center_intensity < 0) center_intensity = 0;
                            if (center_intensity > 1) center_intensity = 1;
                            
                            brightness = int((1 - (i*i + j*j) * 0.05) * 255 * opacity);
                            if (brightness < 0) brightness = 0;
                            
                            if (rand() < star_formation_rate) {
                                r = brightness * 0.8;
                                g = brightness * 0.9;
                                b = brightness;
                            } else {
                                temperature = 5000 + 5000 * (1 - distance_from_center / (cols/2));
                                if (temperature > 10000) {
                                    r = brightness * 0.8;
                                    g = brightness * 0.9;
                                    b = brightness;
                                } else if (temperature > 7500) {
                                    r = g = b = brightness;
                                } else if (temperature > 6000) {
                                    r = g = brightness;
                                    b = brightness * 0.8;
                                } else {
                                    r = brightness;
                                    g = brightness * 0.7;
                                    b = brightness * 0.4;
                                }
                            }
                            
                            central_factor = 1 + (central_brightness - 1) * (1 - distance_from_center / (cols/4));
                            r *= central_factor;
                            g *= central_factor;
                            b *= central_factor;

                            if (rand() < dust_density && distance_from_center > cols/8) {
                                dust_factor = 0.6 + rand() * 0.2;
                                r *= dust_factor;
                                g *= dust_factor;
                                b *= dust_factor;
                            }

                            if (rand() < cluster_chance) {
                                cluster_brightness = 1.2 + rand() * 0.3;
                                r *= cluster_brightness;
                                g *= cluster_brightness;
                                b *= cluster_brightness;
                            }

                            r = (r > 255) ? 255 : r;
                            g = (g > 255) ? 255 : g;
                            b = (b > 255) ? 255 : b;
                            
                            char = (rand() < 0.05) ? "*" : ".";
                            printf "\033[%d;%dH\033[38;2;%d;%d;%dm%s\033[0m", y, x, r, g, b, char;
                        }
                    }
                }
            }
        }
    }' | sort -u | tr '\n' ' '
}

# Growth phase with rotation
angle=0
seed=$RANDOM
for size in $(seq $MIN_SIZE $GROWTH_STEP $MAX_SIZE); do
    clear
    growth_factor=$(echo "scale=2; ($size - $MIN_SIZE) / ($MAX_SIZE - $MIN_SIZE)" | bc)
    draw_spiral $size $angle 1 $growth_factor $seed
    
    # Calculate rotation speed based on size
    if (( $(echo "$growth_factor > $SLOWDOWN_THRESHOLD" | bc -l) )); then
        rotation_speed=$(echo "scale=2; $INITIAL_ROTATION_SPEED * (1 - ($growth_factor - $SLOWDOWN_THRESHOLD) / (1 - $SLOWDOWN_THRESHOLD))" | bc)
        # Ensure rotation_speed doesn't go below MIN_ROTATION_SPEED
        rotation_speed=$(echo "if ($rotation_speed < $MIN_ROTATION_SPEED) $MIN_ROTATION_SPEED else $rotation_speed" | bc)
    else
        rotation_speed=$INITIAL_ROTATION_SPEED
    fi
    
    angle=$(echo "($angle + $rotation_speed) % 360" | bc)
    
    # Calculate sleep duration based on rotation speed
    sleep_duration=$(echo "scale=4; $GROWTH_SPEED * (1 + ($INITIAL_ROTATION_SPEED - $rotation_speed) / $INITIAL_ROTATION_SPEED)" | bc)
    
    # Ensure sleep_duration is a valid number and not empty
    sleep_duration=$(echo "$sleep_duration" | grep -o '[0-9.]*')
    
    # If sleep_duration is empty or zero, use a default value
    if [ -z "$sleep_duration" ] || [ "$sleep_duration" = "0" ]; then
        sleep_duration=$GROWTH_SPEED
    fi
    
    sleep $sleep_duration
done

# Rotation phase
rotation_count=0
while [ $rotation_count -lt $ROTATIONS ]; do
    clear
    draw_spiral $MAX_SIZE $angle 1 1 $seed
    sleep $sleep_duration
    
    # Update angle
    angle=$(echo "($angle + $rotation_speed) % 360" | bc)

    # Increment rotation_count when a full rotation is completed or nearly completed
    if [ $(echo "$angle < $rotation_speed" | bc) -eq 1 ]; then
        rotation_count=$((rotation_count + 1))
        echo "Completed rotation $rotation_count of $ROTATIONS" >&2
    fi
done

tput cup $LINES 0
tput cnorm
