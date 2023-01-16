/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 vertexColor;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec4 vertexPos;

    // View matrix uniforms
    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Get vertex position (feet player pos)
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
        
        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(gl_MultiTexCoord1.x * 0.00416667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(gl_MultiTexCoord1.xy * 0.00416667);
        #endif
        
	    #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;

            // Convert to clip pos and output as position
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 vertexColor;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec4 vertexPos;

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #ifndef FORCE_DISABLE_WEATHER
        // Get rain strength
        uniform float rainStrength;
    #endif

    #if ANTI_ALIASING >= 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #ifdef WORLD_LIGHT
        // Get shadow fade
        uniform float shdFade;

        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;

            #ifdef SHD_FILTER
                #include "/lib/utility/noiseFunctions.glsl"
            #endif

            #include "/lib/lighting/shdMapping.glsl"
            #include "/lib/lighting/shdDistort.glsl"
        #endif
    #endif

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/simpleShadingForward.glsl"

    void main(){
        // Get albedo color
        vec4 albedo = vec4(vertexColor, 1);

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        // Apply simple shading
        vec4 sceneCol = simpleShadingGbuffers(albedo);

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); // colortex3
    }
#endif