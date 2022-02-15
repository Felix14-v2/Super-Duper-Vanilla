#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    #ifdef BLOOM
        const bool colortex2MipmapEnabled = true;

        uniform sampler2D colortex2;

        uniform float viewHeight;
    #endif

    void main(){
        #ifdef BLOOM
            float pixelSize = 1.0 / viewHeight;
            vec3 eBloom = texture2D(colortex2, texCoord + vec2(0, pixelSize * 2.0)).rgb * 0.0625;
            eBloom += texture2D(colortex2, texCoord + vec2(0, pixelSize)).rgb * 0.25;
            eBloom += texture2D(colortex2, texCoord).rgb * 0.375;
            eBloom += texture2D(colortex2, texCoord - vec2(0, pixelSize)).rgb * 0.25;
            eBloom += texture2D(colortex2, texCoord - vec2(0, pixelSize * 2.0)).rgb * 0.0625;
            
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(eBloom, 1); //colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(0, 0, 0, 1); //colortex2
        #endif
    }
#endif