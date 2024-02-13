import lib-sampler.glsl

//: param auto channel_basecolor
uniform SamplerSparse basecolor_tex;
//: param auto channel_normal
uniform SamplerSparse normal_tex;

//: param custom {
//:  "default": 0.66,
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Flow Map Strength"
//: }
uniform float flowMapStrengthParam;

//: param custom {
//:  "default": 0.41,
//:   "min": 0.0,
//:   "max": 1.0,
//:   "label": "Layer Mix Intensity"
//: }
uniform float mixIntensity;

//: param custom {
//:  "default": 6,
//:   "min": 1,
//:   "max": 12,
//:   "label": "Layer Count"
//: }
uniform int layerCountParam;

void shade(V2F inputs) {
  vec3 normal = textureSparse(normal_tex, inputs.sparse_coord).rgb;
  vec3 finalColor1 = vec3(0.5);
  vec3 finalColor2 = vec3(0.5);
  float layerStrength = 1.0;
  int layerCount = layerCountParam * 2;
  float layerStep = layerStrength/layerCount;
  float flowMapStrength = flowMapStrengthParam * 0.05;

  // Forwards
  for(int i = 0; i < layerCount; i++) {
    SparseCoord coord = inputs.sparse_coord;
    coord.tex_coord += (vec2(normal.r, normal.g) - vec2(0.5, 0.5)) * flowMapStrength * layerStrength;
    vec3 baseColor = getBaseColor(basecolor_tex, coord);

    if (i % 2 == 0) {
      finalColor1 *= (1-mixIntensity) + baseColor * mixIntensity;
    } else {
      finalColor1 += baseColor * (mixIntensity);
    }
    layerStrength -= layerStep;
  }

  layerStrength = 1.0;

  //Backwards
  for(int i = 0; i < layerCount; i++) {
    SparseCoord coord = inputs.sparse_coord;
    coord.tex_coord += (vec2(1 - normal.r, 1 - normal.g) - vec2(0.5, 0.5)) * flowMapStrength * layerStrength;
    vec3 baseColor = getBaseColor(basecolor_tex, coord);

    if (i % 2 == 0) {
      finalColor2 *= (1-mixIntensity) + baseColor * mixIntensity;
    } else {
      finalColor2 += baseColor * (mixIntensity);
    }
    layerStrength -= layerStep;
  }

  vec3 finalMix = (finalColor2 + finalColor1)/2;
  diffuseShadingOutput(finalMix);
}
