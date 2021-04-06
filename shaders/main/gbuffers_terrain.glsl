#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/vertexWave.glsl"

INOUT vec2 lmcoord;
INOUT vec2 texcoord;

INOUT vec3 norm;

INOUT vec4 entity;
INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    attribute vec2 mc_midTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        vec4 vertexPos = gl_ModelViewMatrix * gl_Vertex;

        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        entity = mc_Entity;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));

	    norm = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(tangent, binormal, norm);

        vertexPos = gbufferModelViewInverse * vertexPos;

	    getWave(vertexPos.xyz, vertexPos.xyz + cameraPosition, texcoord, mc_midTexCoord, mc_Entity.x);

	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D lightmap;
    uniform sampler2D texture;

    void main(){
        vec4 color = texture2D(texture, texcoord);
        vec2 nLmCoord = squared(lmcoord);

        float maxCol = maxC(color.rgb); float satCol = rgb2hsv(color).y;

        float metallic = (entity.x >= 10008.0 && entity.x <= 10010.0) || entity.x == 10015.0 ? 0.75 : 0.0;
        float ss = (entity.x >= 10001.0 && entity.x <= 10004.0) || entity.x == 10007.0 || entity.x == 10011.0 || entity.x == 10013.0 ? sqrt(maxCol) * 0.8 : 0.0;
        float emissive = entity.x == 10005.0 || entity.x == 10006.0 ? maxCol
            : entity.x == 10014.0 ? satCol : 0.0;

        vec4 nGlcolor = glcolor * (1.0 - emissive) + sqrt(sqrt(glcolor)) * emissive;

        #ifndef WHITE_MODE
            color.rgb *= nGlcolor.rgb;
        #else
            #ifdef WHITE_MODE_F
                color.rgb = nGlcolor.rgb;
            #else
                color.rgb = vec3(1.0);
            #endif
        #endif
        
        color.rgb *= texture2D(lightmap, nLmCoord).rgb * (1.0 - emissive) + emissive;

        vec3 normal = mat3(gbufferModelViewInverse) * norm;

    /* DRAWBUFFERS:01234 */
        gl_FragData[0] = color; //gcolor
        gl_FragData[1] = vec4(normal * 0.5 + 0.5, 1.0); //colortex1
        gl_FragData[2] = vec4(nLmCoord, ss, 1.0); //colortex2
        gl_FragData[3] = vec4(metallic, emissive, 0.0, 1.0); //colortex3
        gl_FragData[4] = vec4(1.0, 0.0, color.a, 1.0); //colortex4
    }
#endif