vec3 complexShadingDeferred(in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 normal, in vec3 albedo, in float viewDotInvSqrt, in float metallic, in float smoothness, in vec3 dither){
	#if defined ROUGH_REFLECTIONS || defined SSGI
		vec3 noiseUnitVector = generateUnitVector(dither.xy);
	#endif

	// Calculate SSGI
	#ifdef SSGI
		// Get SSGI screen coordinates
		vec3 SSGIcoord = rayTraceScene(screenPos, viewPos, generateCosineVector(normal, noiseUnitVector), dither.z, SSGI_STEPS, SSGI_BISTEPS);

		// If sky don't do SSGI
		#ifdef PREVIOUS_FRAME
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(colortex5, toPrevScreenPos(SSGIcoord.xy), 0).rgb;
		#else
			if(SSGIcoord.z > 0.5) sceneCol += albedo * textureLod(gcolor, SSGIcoord.xy, 0).rgb;
		#endif
	#endif

	// If smoothness is 0, don't do reflections
	if(smoothness > 0.005){
		vec3 nViewPos = viewPos * viewDotInvSqrt;

		#ifdef ROUGH_REFLECTIONS
			// Rough the normals with noise
			normal = generateCosineVector(normal, noiseUnitVector * squared(1.0 - smoothness) * 0.5);
		#endif

		float NV = dot(normal, -nViewPos);
		float cosTheta = exp2(-9.28 * max(NV, 0.0));

		// Get reflected view direction
		// reflect(direction, normal) = direction - 2.0 * dot(normal, direction) * normal
		vec3 reflectedViewDir = nViewPos + (2.0 * NV) * normal;

		// Calculate SSR and sky reflections
		#ifdef SSR
			// Get SSR screen coordinates
			vec3 SSRCoord = rayTraceScene(screenPos, viewPos, reflectedViewDir, dither.z, SSR_STEPS, SSR_BISTEPS);
			
			#ifdef PREVIOUS_FRAME
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyReflection(mat3(gbufferModelViewInverse) * reflectedViewDir) : textureLod(colortex5, toPrevScreenPos(SSRCoord.xy), 0).rgb;
			#else
				// Get reflections and check for sky
				vec3 reflectCol = SSRCoord.z < 0.5 ? getSkyReflection(mat3(gbufferModelViewInverse) * reflectedViewDir) : textureLod(gcolor, SSRCoord.xy, 0).rgb;
			#endif
		#else
			vec3 reflectCol = getSkyReflection(reflectedSkyDir);
		#endif

		// Modified version of BSL's reflection PBR calculation
		if(metallic > 0.9){
			vec3 fresnel = getFresnelSchlick(albedo, cosTheta) * smoothness;
			sceneCol = sceneCol * (1.0 - smoothness) + reflectCol * fresnel;
		}else{
			float fresnel = getFresnelSchlick(metallic, cosTheta) * smoothness;
			sceneCol = sceneCol * (1.0 - fresnel) + reflectCol * fresnel;
		}
	}

	return sceneCol;
}