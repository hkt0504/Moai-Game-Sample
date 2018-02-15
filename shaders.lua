function point_lighting_shader_desktop(lightx, lighty, lightz, intensity, range, red, green, blue, am_red, am_green, am_blue, move_with_prop, isBlack)  
  local fsh = [[  
    varying MEDP vec2 uvVarying;
    varying MEDP vec4 positionVarying;
    varying MEDP vec4 colourVarying;
    
    varying MEDP vec4 light;
    varying MEDP vec3 lightColour;

    uniform sampler2D diffuseMap;
    uniform sampler2D normalMap;

    uniform float light_intensity, light_range;
    
    uniform MEDP float ambientColourR;
    uniform MEDP float ambientColourG;
    uniform MEDP float ambientColourB;
    
    uniform mat4 worldMatrix;               // Sum of all MOAITransforms on object
    
    vec2 resolution = vec2(1.0, 1.0);
    vec3 attenuation = vec3(1.0, 1.0, 1.0); 
    

    void main()
    {
      //sample color & normals from our textures
      vec4 color = texture2D(diffuseMap, uvVarying);
      vec3 nColor = texture2D(normalMap, uvVarying).rgb;

      //normals need to be converted to [-1.0, 1.0] range and normalized
      vec3 normal = normalize(nColor * 2.0 - 1.0);

      //here we do a simple distance calculation
      vec3 deltaPos = vec3(light.xy - positionVarying.xy, light.z);
      
      float vertex_dist = length (deltaPos);
      
      //gl_FragColor = vec4(deltaPos, light.a);
      // Decay light factor depending on the vertex distance from light source
      float decay = max( 0.0, (light_range - vertex_dist )/ light_range ) * 2.0;

      vec3 lightDir = normalize(deltaPos);
      float lambert = clamp(dot(normal, lightDir), 0.0, 1.0);

      //now let's get a nice little falloff
      float d = sqrt(dot(deltaPos, deltaPos));      
      float att = ( attenuation.x + (attenuation.y*d) + (attenuation.z*d*d) );

      vec3 ambientColor = vec3(ambientColourR, ambientColourG, ambientColourB);
      
      vec3 result = ambientColor + (lightColour.rgb * lambert * light_intensity * decay) * att;
      result *= color.rgb;
    
      vec3 resCol = colourVarying.rgb * result.rgb;
      gl_FragColor = vec4(colourVarying.rgb * result.rgb, colourVarying.a * color.a);
        
      //if(positionVarying[1] > 300.0)
       // gl_FragColor = vec4(1.0,0.0,0.0,1.0);

      //gl_FragColor = vec4((positionVarying[1]+1.0)/2.0, 0.0, 0.0, 1.0);
         //gl_FragColor = texture2D(normalMap, uvVarying);
    }
  ]]

  local vsh = [[ 
    attribute vec4 position;
    attribute vec2 uv;
    attribute vec4 colour;
    
    uniform MEDP float lightX;
    uniform MEDP float lightY;
    uniform MEDP float lightZ;

    uniform MEDP float lightColourR;
    uniform MEDP float lightColourG;
    uniform MEDP float lightColourB;

    uniform mat4 worldMatrix;               // Sum of all MOAITransforms on object
    
    varying vec2 uvVarying;
    varying MEDP vec4 colourVarying;
    varying vec4 positionVarying;   
    varying vec4 light;
    varying vec3 lightColour;
    
    void main () {
      uvVarying = uv;
        
      positionVarying = position *worldMatrix;
      
      light = vec4(lightX, lightY, lightZ, 1.0) * worldMatrix;
      
      lightColour = vec3(lightColourR, lightColourG, lightColourB);

      colourVarying = colour;
      
      gl_Position = position;          
    }
  ]]
  
  local program = MOAIShaderProgram.new ()
  
  program:setVertexAttribute ( 1, 'position' )
  program:setVertexAttribute ( 2, 'uv' )
  program:setVertexAttribute ( 3, 'colour' )
  
  program:reserveUniforms ( 16 )  
  program:declareUniform( 1, 'diffuseMap', MOAIShaderProgram.UNIFORM_TYPE_INT )
  program:declareUniform( 2, 'normalMap', MOAIShaderProgram.UNIFORM_TYPE_INT )
  program:declareUniform( 3, 'lightX', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 4, 'lightY', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 5, 'lightZ', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 6, 'lightColourR', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 7, 'lightColourG', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 8, 'lightColourB', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 9, 'light_intensity', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 10, 'light_range', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 11, 'ambientColourR', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 12, 'ambientColourG', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 13, 'ambientColourB', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 14, 'moveWithProp', MOAIShaderProgram.UNIFORM_TYPE_FLOAT )
  program:declareUniform( 15, 'isBlack', MOAIShaderProgram.UNIFORM_TYPE_FLOAT ) 
  program:declareUniform( 16, 'worldMatrix', MOAIShaderProgram.UNIFORM_TYPE_FLOAT, MOAIShaderProgram.UNIFORM_WIDTH_MATRIX_4X4 )  
  
  program:load ( vsh, fsh )
  program:reserveTextures ( 2 ) 
  program:setTexture ( 1, 1, 1 ) 
  program:setTexture ( 2, 2, 2 ) 
  
  program:reserveGlobals(1)  
  --program:setGlobal ( 1, MOAIShaderProgram.GLOBAL_WORLD_NORMAL , 16, 1 )
  program:setGlobal ( 1, MOAIShaderProgram.GLOBAL_MODEL_TO_WORLD_MTX , 16, 1 )
  
  local shader = MOAIShader.new ()
  shader:setProgram(program)    
  shader:setUniform( 1, 0 )
  shader:setUniform( 2, 1 )
  shader:setUniform( 3, lightx )
  shader:setUniform( 4, lighty )
  shader:setUniform( 5, lightz )
  shader:setUniform( 6, red)
  shader:setUniform( 7, green )
  shader:setUniform( 8, blue )
  shader:setUniform( 9, intensity / 5)
  shader:setUniform( 10, range )
  shader:setUniform( 11, am_red)  
  shader:setUniform( 12, am_green )
  shader:setUniform( 13, am_blue )
  
  if move_with_prop ~= nil then
    shader:setUniform( 14, 1.0)
  else 
    shader:setUniform( 14, 0.0)
  end

  if isBlack then
    shader:setUniform( 15, 1.0)
  else 
    shader:setUniform( 15, 0.0)
  end
  
  return shader
end