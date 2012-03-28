

#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <string.h>

#include <time.h>




#include <OpenGLES/ES1/gl.h>

// ZLIB for data decompression
#include <zlib.h>


// custom objects



/////////////////////////////////////////////////
// fluid object definition                     //
/////////////////////////////////////////////////

#include "flotte.h"



//-----------------------------------
// constructor
//
// define aSize X aSize columns of
// fluid
//-----------------------------------

dmFlotte::dmFlotte(int rez)
{

   // allocate texture (3/4 RBBA components)

   _TexBuff[0] = new GLubyte[TEX_WIDTH1*TEX_HEIGHT1*TEX_COMP1];
   _TexBuff[1] = new GLubyte[TEX_WIDTH2*TEX_HEIGHT2*TEX_COMP2];


   _texwidth[0]  = TEX_WIDTH1;
   _texheight[0] = TEX_HEIGHT1;

   _texwidth[1]  = TEX_WIDTH2;
   _texheight[1] = TEX_HEIGHT2;


   // initialize some fields

   _angle = 0;


   // initial conditions

   _p1 = &_Flot1; // FRONT MAP
   _p2 = &_Flot2; // BACK MAP

   dmFlotte::init_Flot();

   // by default high tesselation

   //_lowtesselation = false;
   //_hightesselation = true;

    // andreico
   _lowtesselation = true;
   _hightesselation = false;

   if (rez == FLOT_MEDIUMRES)
     _hightesselation = false;
   else if (rez == FLOT_LOWRES)
     _lowtesselation = true;


   // prebuild geometric model

   dmFlotte::_prebuild_Flot();

   // read textures files ...

   // DS improve datas
	
	dmFlotte::_load_tex(0, (char *)[ [[NSBundle mainBundle] pathForResource:@"map2" ofType:@"dat"] cStringUsingEncoding:NSUTF8StringEncoding]);   // sky envmap
	dmFlotte::_load_tex(1, (char *)[ [[NSBundle mainBundle] pathForResource:@"map1" ofType:@"dat"] cStringUsingEncoding:NSUTF8StringEncoding]);   // logo ds
	

	
   _textured = TRUE;


   // by default multitextured
   _multitex = true;
   _freezemultitex = false;



   dmFlotte::_init_GfxContext(); // initialize gfx context


   // current clock
   _last_msTime = ( (clock() * 1000) / CLOCKS_PER_SEC ) - 100.0f;
   _cur_msTime = _last_msTime + 100.0f;

}

//-----------------------------------
// destructor
//-----------------------------------

dmFlotte::~dmFlotte(void)
{

   if (_textured)
   {
       GLuint deltex[] = {1,2};
       glDeleteTextures(2, deltex);  // delete textures ...
   }

   if (_TexBuff[0])
   {
      delete[] _TexBuff[0];
   }

   if (_TexBuff[1])
   {
      delete[] _TexBuff[1];
   }
}


//-----------------------------------
// initialize graphics context
//
// materials, envmaps ...
//-----------------------------------

void dmFlotte::_init_GfxContext(void)
{

    
    _multitex = false; // no multitexturing - two pass rendering



    if (_freezemultitex == true)
    {
       _multitex = false;
    }



    /* Zbuff on ... */

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    // no face culling to have recto-verso

    glShadeModel(GL_SMOOTH); // shading Gouraud


    /***********************************/
    /* define 1st texture map (envmap) */
    /***********************************/

    glBindTexture(GL_TEXTURE_2D, 1);


    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
  //  glPixelStorei(0x0CF0,0);



    if (TEX_COMP1 == 3)
    {
       glTexImage2D(GL_TEXTURE_2D, 0, 3, _texwidth[0] , _texheight[0], 0, GL_RGB, GL_UNSIGNED_BYTE, _TexBuff[0]);
    }
    else if (TEX_COMP1 == 4)
    {
       glTexImage2D(GL_TEXTURE_2D, 0, 4, _texwidth[0] , _texheight[0], 0, GL_RGBA, GL_UNSIGNED_BYTE, _TexBuff[0]);
    }

    /* sampling parameters */

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);


	

    /***************************************/
    /* define 2nd texture map (background) */
    /***************************************/

    glBindTexture(GL_TEXTURE_2D, 2);


    glPixelStorei(GL_UNPACK_ALIGNMENT,1);
    //glPixelStorei(0x0CF0,0);

    // check if support 1024x1024 texture
    GLint tex_size = 1024;
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &tex_size);

	
    if (tex_size < _texwidth[1])
    {
       // 256x256
       dmFlotte::_reduce_tex(1, _TexBuff[1]);

       if (TEX_COMP2 == 3)
       {
          glTexImage2D(GL_TEXTURE_2D, 0, 3, _texwidth[1] >> 2, _texheight[1] >> 2, 0, GL_RGB, GL_UNSIGNED_BYTE, _TexBuff[1]);
       }
       else if (TEX_COMP2 == 4)
       {
          glTexImage2D(GL_TEXTURE_2D, 0, 4, _texwidth[1] >> 2, _texheight[1] >> 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, _TexBuff[1]);
       }
    }
    else
    {
       // RGB4 or RGBA4

       if (TEX_COMP2 == 3)
       {
          glTexImage2D(GL_TEXTURE_2D, 0, 3, _texwidth[1] , _texheight[1], 0, GL_RGB, GL_UNSIGNED_BYTE, _TexBuff[1]);
       }
       else if (TEX_COMP2 == 4)
       {
          glTexImage2D(GL_TEXTURE_2D, 0, 4, _texwidth[1] , _texheight[1], 0, GL_RGBA, GL_UNSIGNED_BYTE, _TexBuff[1]);
       }
    }

    /* sampling parameters */

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);




	
    /* scale projection matrix for vertices... */

    glMatrixMode(GL_MODELVIEW);
    glScalef(.01, .01, .01);


}


//-----------------------------------
// initial conditions : every heights
// at zero
//-----------------------------------

void dmFlotte::init_Flot(void)
{
    memset((unsigned char*)(*_p1), 0, sizeof(int)*(FLOTSIZE+2)*(FLOTSIZE+2));
    memset((unsigned char*)(*_p2), 0, sizeof(int)*(FLOTSIZE+2)*(FLOTSIZE+2));
}

//-----------------------------------
// trace a hole at normalized
// coordinates
//-----------------------------------

void dmFlotte::setWave(float aX, float aY, int aVal)
{
    int x = FLOT_MILX + (int)(2.0f*(aX - 0.5f)*FLOT_LARG);
    int y = FLOT_MILY + (int)(2.0f*(aY - 0.5f)*FLOT_LARG);

    // check periodicity
    while (x > FLOTSIZE)  x -= FLOTSIZE;
    while (y > FLOTSIZE)  y -= FLOTSIZE;
    while (x < 0) x += FLOTSIZE;
    while (y < 0) y += FLOTSIZE;


    (*_p1)[x][y] -= aVal;
}

//-----------------------------------
// trace a hole following parametric
// curves
//-----------------------------------

void dmFlotte::runWave(float aPhase, float aCos, float aSin, int aVal)
{
    float r = (_angle*M_PI)/1024.0f;

    int x = FLOT_MILX + ((int) (cos(aCos*r + aPhase)*FLOT_LARG));
    int y = FLOT_MILY + ((int) (sin(aSin*r + aPhase)*FLOT_LARG));

    if (x > FLOTSIZE)  x = FLOTSIZE;
    if (y > FLOTSIZE)  y = FLOTSIZE;
    if (x < 0) x = 0;
    if (y < 0) y = 0;


    (*_p1)[x][y] -= aVal;
}



//-----------------------------------
// trace a random hole
//-----------------------------------

void dmFlotte::randomWave(void)
{
    (*_p1)[random()%FLOTSIZE+1][random()%FLOTSIZE+1] -= random()%128;
}


//-----------------------------------
// measure elapsed time ...
//-----------------------------------
bool dmFlotte::bench(float rate)
{
    _cur_msTime = (clock() * 1000) / CLOCKS_PER_SEC;

    // don't run to quick otherwise it doesn't look like water
    return (_cur_msTime - _last_msTime) >= rate;
}

void dmFlotte::nexttime(void)
{
    _last_msTime = _cur_msTime;
}

//-----------------------------------
// update to next state of fluid
// model
//-----------------------------------

void dmFlotte::update(void)
{

    // new angle for parametric curves
    _angle = (_angle+2) & 1023;


    // fluid update
    dmFlotte::_new_Flot();

    // smoothing
    dmFlotte::_Lisse_Flot();

}

//----------------------------------------
// build geometric model
//----------------------------------------

void dmFlotte::build(void)
{

    dmFlotte::_build_Flot();
}

//----------------------------------------
// physical calculus for fluid model
//----------------------------------------


void dmFlotte::_new_Flot(void)
{

     register int x,y, step;
     register int *ptr;
     int (*q)[FLOTSIZE+2][FLOTSIZE+2];


     // discretized differential equation

     for(x=1; x<=FLOTSIZE; x++)
     {
        for(y=0; y<=FLOTSIZE; y ++)
        {
           (*_p1)[x][y] = (((*_p2)[x-1][y]+(*_p2)[x+1][y]+(*_p2)[x][y-1]+(*_p2)[x][y+1]) >> 1) - (*_p1)[x][y];
           (*_p1)[x][y] -= (*_p1)[x][y] >> 4;
        }
     }


     // copy borders to make the map periodic


     memcpy(&((*_p1)[0][0]), &((*_p1)[1][0]), sizeof(int)*(FLOTSIZE+2));
     memcpy(&((*_p1)[FLOTSIZE+1][0]), &((*_p1)[1][0]), sizeof(int)*(FLOTSIZE+2));

     step = (FLOTSIZE+2);

     for(x=0, ptr = &((*_p1)[0][0]); x<(FLOTSIZE+1); x++, ptr += step)
     {
        ptr[0] = ptr[1];
        ptr[FLOTSIZE+1] = ptr[1];
     }

     /* swap buffers t and t-1, we advance in time */


     q=_p1;
     _p1=_p2;
     _p2=q;


}



//----------------------------------------
// filter and smooth producted values
//----------------------------------------


void dmFlotte::_Lisse_Flot(void)
{
     register int x,y,i;


     for(x=1; x<FLOTSIZE+1; x++)
     {
        for(y=1; y<FLOTSIZE+1; y++)
        {
           _Lisse[x][y] = (3*(*_p1)[x][y]+2*(*_p1)[x+1][y]+2*(*_p1)[x][y+1]+(*_p1)[x+1][y+1]) >> 3;
        }
     }


     for(i=1; i<4; i++)
     {
       for(x=1; x<FLOTSIZE+1; x++)
       {
          for(y=1; y<FLOTSIZE+1; y++)
          {
             _Lisse[x][y] = (3*_Lisse[x][y]+2*_Lisse[x+1][y]+2*_Lisse[x][y+1]+_Lisse[x+1][y+1]) >> 3;
          }
       }
     }


}


//------------------------------------------
// pre-building of a geometric model
//------------------------------------------

void dmFlotte::_prebuild_Flot(void)
{
     register float h1,xmin,ymin;
     register int x,y;


     if (_hightesselation)
     {
        /* vertices calculus -> we already know X and Y */
        /* calculus of background texture coordinates */

        for(x=1; x<=FLOTSIZE; x++)
        {
           xmin = (x-FLOT_MILX)/6.5f;

           for(y=1; y<=FLOTSIZE; y++)
           {
              ymin = (y-FLOT_MILY)/7.5f;

              _sommet[(x-1) *2][(y-1) *2][0] = xmin;
              _sommet[(x-1) *2][(y-1) *2][1] = ymin;

              _uvmap[(x-1) *2][(y-1) *2][0] = (x-1)*(1.0f/(FLOTSIZE-1));
              _uvmap[(x-1) *2][(y-1) *2][1] = (y-1)*(1.0f/(FLOTSIZE-1));
           }

        }


        // build vertices in-between
        for(x=0;  x<= FLOTSIZE*2 - 1; x+=2)     // even rows
        {
           for(y=1; y<=FLOTSIZE*2 - 2;  y+=2)   // odd columns
           {
              _sommet[x][y][0]  = (_sommet[x][y-1][0] + _sommet[x][y+1][0]) / 2.0f;
              _sommet[x][y][1]  = (_sommet[x][y-1][1] + _sommet[x][y+1][1]) / 2.0f;
              _uvmap[x][y][0]  = (_uvmap[x][y-1][0] + _uvmap[x][y+1][0]) / 2.0f;
              _uvmap[x][y][1]  = (_uvmap[x][y-1][1] + _uvmap[x][y+1][1]) / 2.0f;
           }

        }

        // build vertices in-between
        for(x=1;  x<= FLOTSIZE*2 - 2; x+=2)    // odd rows
        {
           for(y=0; y<=FLOTSIZE*2 - 1;  y++)   // every columns
           {
              _sommet[x][y][0]  = (_sommet[x-1][y][0] + _sommet[x+1][y][0]) / 2.0f;
              _sommet[x][y][1]  = (_sommet[x-1][y][1] + _sommet[x+1][y][1]) / 2.0f;
              _uvmap[x][y][0]  = (_uvmap[x-1][y][0] + _uvmap[x+1][y][0]) / 2.0f;
              _uvmap[x][y][1]  = (_uvmap[x-1][y][1] + _uvmap[x+1][y][1]) / 2.0f;
           }

        }


        /* nomals to faces calculus : Z component is constant */

        // -> simplified cross product and optimized knowing that we have
        //    a distance of 1.0 between each fluid cells.

        for(x=0; x < (FLOTSIZE << 1)-1; x++)
        {
           for(y=0; y < (FLOTSIZE << 1)-1; y++)
           {
              _normal[x][y][2] = 0.01f;
           }
        }


        //..............................................................................................................
        //
        // the following calculus is useless because each cell of _snormal[x][y][2] = 0.01+0.01+0.01+0.01 = 0.04
        //..............................................................................................................


        /* copy borders of the map (Z component only) for periodicity */

        memcpy((char*) &_normal[FLOTSIZE*2-1][0][0], (char*) &_normal[FLOTSIZE*2-2][0][0], 3*sizeof(float)*FLOTSIZE*2);

        for(x=0; x < FLOTSIZE*2; x++)
        {
           _normal[x][FLOTSIZE*2-1][2] = _normal[x][FLOTSIZE*2-2][2];
        }


        /* calculate normals to vertices (Z component only)*/

        for(x=1; x < FLOTSIZE*2-1; x++)
        {
           for(y=1; y < FLOTSIZE*2-1; y++)
           {
              _snormal[x][y][2] = _normal[x-1][y][2]+_normal[x+1][y][2]+_normal[x][y-1][2]+_normal[x][y+1][2];
           }
        }


        /* copy borders of the map (Z component only) for periodicity */

        for(x=0; x < FLOTSIZE*2; x++)
        {
           _snormal[x][0][2] = _normal[x][0][2];
           _snormal[x][FLOTSIZE*2-1][2] = _normal[x][FLOTSIZE*2-1][2];
        }

        memcpy((char*) &_snormal[0][0][0], (char*) &_normal[0][0][0], 3*sizeof(float)*FLOTSIZE*2);
        memcpy((char*) &_snormal[FLOTSIZE*2-1][0][0], (char*) &_normal[FLOTSIZE*2-1][0][0], 3*sizeof(float)*FLOTSIZE*2);

   } // end hightesselation
   else
   {
        /* vertices calculus -> we already know X and Y */
        /* calculus of background texture coordinates */

        for(x=1; x<=FLOTSIZE; x++)
        {
           xmin = (x-FLOT_MILX)/6.5f;

           for(y=1; y<=FLOTSIZE; y++)
           {
              ymin = (y-FLOT_MILY)/7.5f;

              _sommet[x-1][y-1][0] = xmin;
              _sommet[x-1][y-1][1] = ymin;

              _uvmap[x-1][y-1][0] = (x-1)*(1.0f/(FLOTSIZE-1));
              _uvmap[x-1][y-1][1] = (y-1)*(1.0f/(FLOTSIZE-1));
           }

        }


        /* nomals to faces calculus : Z component is constant */

        // -> simplified cross product and optimized knowing that we have
        //    a distance of 1.0 between each fluid cells.

        for(x=0; x < FLOTSIZE-1; x++)
        {
           for(y=0; y < FLOTSIZE-1; y++)
           {
              _normal[x][y][2] = 0.01f;
           }
        }


        //..............................................................................................................
        //
        // the following calculus is useless because each cell of _snormal[x][y][2] = 0.01+0.01+0.01+0.01 = 0.04
        //..............................................................................................................


        /* copy borders of the map (Z component only) for periodicity */

        memcpy((char*) &_normal[FLOTSIZE-1][0][0], (char*) &_normal[FLOTSIZE-2][0][0], 3*sizeof(float)*FLOTSIZE);

        for(x=0; x < FLOTSIZE; x++)
        {
           _normal[x][FLOTSIZE-1][2] = _normal[x][FLOTSIZE-2][2];
        }


        /* calculate normals to vertices (Z component only)*/

        for(x=1; x < FLOTSIZE-1; x++)
        {
           for(y=1; y < FLOTSIZE-1; y++)
           {
              _snormal[x][y][2] = _normal[x-1][y][2]+_normal[x+1][y][2]+_normal[x][y-1][2]+_normal[x][y+1][2];
           }
        }


        /* copy borders of the map (Z component only) for periodicity */

        for(x=0; x < FLOTSIZE; x++)
        {
           _snormal[x][0][2] = _normal[x][0][2];
           _snormal[x][FLOTSIZE-1][2] = _normal[x][FLOTSIZE-1][2];
        }

        memcpy((char*) &_snormal[0][0][0], (char*) &_normal[0][0][0], 3*sizeof(float)*FLOTSIZE);
        memcpy((char*) &_snormal[FLOTSIZE-1][0][0], (char*) &_normal[FLOTSIZE-1][0][0], 3*sizeof(float)*FLOTSIZE);

   } // end lowtesselation
}

//----------------------------------------
// construction of a geometric model
//----------------------------------------

void dmFlotte::_build_Flot(void)
{
     register float h1,sqroot;
     register int x,y;

     float L[3], V[3], R[3], RV[3], ls, lz, radius, dotprod;

     if (_hightesselation)
     {

        /* calculate vertices : Z component */

        for(x=1; x<=FLOTSIZE; x++)
        {
           for(y=1; y<=FLOTSIZE; y++)
           {
              if ( (h1 = (_Lisse[x][y] / 100.0f)) < 0.0f)
              {
                 h1 = 0.0f;
              }

              _sommet[(x-1) << 1][(y-1) << 1][2] = h1;
           }
        }

        // construct vertices in-between
        for(x=0;  x<= FLOTSIZE*2 - 1; x+=2)     // even rows
        {
           for(y=1; y<=FLOTSIZE*2 - 2;  y+=2)   // odd columns
           {
              _sommet[x][y][2]  = (_sommet[x][y-1][2] + _sommet[x][y+1][2]) / 2.0f;
           }
        }

        // construct vertices in-between
        for(x=1;  x<= FLOTSIZE*2 - 2; x+=2)    // even rows
        {
           for(y=0; y<=FLOTSIZE*2 - 1;  y++)   // every columns
           {
              _sommet[x][y][2]  = (_sommet[x-1][y][2] + _sommet[x+1][y][2]) / 2.0f;
           }
        }



        /* calculate normals to faces : components X and Y */

        // -> simplified cross product knowing that we have a distance of 1.0 between
        //    each fluid cells.

        for(x=0; x < FLOTSIZE*2 -1; x++)
        {
           for(y=0; y < FLOTSIZE*2 -1; y++)
           {
              _normal[x][y][0] = 0.1f*(_sommet[x][y][2]-_sommet[x+1][y][2]);
              _normal[x][y][1] = 0.1f*(_sommet[x][y][2]-_sommet[x][y+1][2]);
           }
        }


        /* copy map borders(components X and Y only) for periodicity */

        memcpy((char*) &_normal[FLOTSIZE*2-1][0][0], (char*) &_normal[FLOTSIZE*2-2][0][0], 3*sizeof(float)*FLOTSIZE*2);

        for(x=0; x < FLOTSIZE*2; x++)
        {
           _normal[x][FLOTSIZE*2-1][0] = _normal[x][FLOTSIZE*2-2][0];
           _normal[x][FLOTSIZE*2-1][1] = _normal[x][FLOTSIZE*2-2][1];
        }


        /* calculate normals to vertices (components X and Y only) */

        for(x=1; x < FLOTSIZE*2-1; x++)
        {
           for(y=1; y < FLOTSIZE*2-1; y++)
           {
              _snormal[x][y][0] = _normal[x-1][y][0]+_normal[x+1][y][0]+_normal[x][y-1][0]+_normal[x][y+1][0];
              _snormal[x][y][1] = _normal[x-1][y][1]+_normal[x+1][y][1]+_normal[x][y-1][1]+_normal[x][y+1][1];
           }
        }


        /* copy map borders (components X and Y only) */

        for(x=0; x < FLOTSIZE*2; x++)
        {
           _snormal[x][0][0] = _normal[x][0][0];
           _snormal[x][0][1] = _normal[x][0][1];
           _snormal[x][FLOTSIZE*2-1][0] = _normal[x][FLOTSIZE*2-1][0];
           _snormal[x][FLOTSIZE*2-1][1] = _normal[x][FLOTSIZE*2-1][1];
        }

        memcpy((char*) &_snormal[0][0][0], (char*) &_normal[0][0][0], 3*sizeof(float)*FLOTSIZE*2);
        memcpy((char*) &_snormal[FLOTSIZE*2-1][0][0], (char*) &_normal[FLOTSIZE*2-1][0][0], 3*sizeof(float)*FLOTSIZE*2);


        /* calculate ourself normalization */

        for(x=0; x < FLOTSIZE*2; x++)
        {
           for(y=0; y < FLOTSIZE*2; y++)
           {


              sqroot = sqrt(_snormal[x][y][0]*_snormal[x][y][0] +
                            _snormal[x][y][1]*_snormal[x][y][1] +
                            0.0016f);


              _snormaln[x][y][0] = _snormal[x][y][0]/sqroot;
              _snormaln[x][y][1] = _snormal[x][y][1]/sqroot;
              _snormaln[x][y][2] = 0.04f/sqroot;             // _snormal[x][y][2] = 0.04


              // perturbate coordinates of background mapping with the components X,Y of normals...
              // simulate refraction

              _newuvmap[x][y][0] = _uvmap[x][y][0] + 0.05f*_snormaln[x][y][0];
              _newuvmap[x][y][1] = _uvmap[x][y][1] + 0.05f*_snormaln[x][y][1];

           }
        }



        // really simple version of a fake envmap generator

        for(x=0; x < FLOTSIZE*2; x++)
        {
           for(y=0; y < FLOTSIZE*2; y++)
           {
              // trick : xy projection of normals  ->  assume reflection in direction of the normals
              //                                       looks ok for non-plane surfaces
              _envmap[x][y][0] = 0.5f + _snormaln[x][y][0]*0.45f;
              _envmap[x][y][1] = 0.5f + _snormaln[x][y][1]*0.45f;

           }
        }

   } // end high tesselation
   else
   {

        /* calculate vertices : Z component */

        for(x=1; x<=FLOTSIZE; x++)
        {
           for(y=1; y<=FLOTSIZE; y++)
           {
              if ( (h1 = (_Lisse[x][y] / 100.0f)) < 0.0f)
              {
                 h1 = 0.0f;
              }

              _sommet[x-1][y-1][2] = h1;
           }
        }


        /* calculate normals to faces : components X and Y */

        // -> simplified cross product knowing that we have a distance of 1.0 between
        //    each fluid cells.

        for(x=0; x < FLOTSIZE-1; x++)
        {
           for(y=0; y < FLOTSIZE-1; y++)
           {
              _normal[x][y][0] = 0.1f*(_sommet[x][y][2]-_sommet[x+1][y][2]);
              _normal[x][y][1] = 0.1f*(_sommet[x][y][2]-_sommet[x][y+1][2]);
           }
        }


        /* copy map borders(components X and Y only) for periodicity */

        memcpy((char*) &_normal[FLOTSIZE-1][0][0], (char*) &_normal[FLOTSIZE-2][0][0], 3*sizeof(float)*FLOTSIZE);

        for(x=0; x < FLOTSIZE; x++)
        {
           _normal[x][FLOTSIZE-1][0] = _normal[x][FLOTSIZE-2][0];
           _normal[x][FLOTSIZE-1][1] = _normal[x][FLOTSIZE-2][1];
        }


        /* calculate normals to vertices (components X and Y only) */

        for(x=1; x < FLOTSIZE-1; x++)
        {
           for(y=1; y < FLOTSIZE-1; y++)
           {
              _snormal[x][y][0] = _normal[x-1][y][0]+_normal[x+1][y][0]+_normal[x][y-1][0]+_normal[x][y+1][0];
              _snormal[x][y][1] = _normal[x-1][y][1]+_normal[x+1][y][1]+_normal[x][y-1][1]+_normal[x][y+1][1];
           }
        }


        /* copy map borders (components X and Y only) */

        for(x=0; x < FLOTSIZE; x++)
        {
           _snormal[x][0][0] = _normal[x][0][0];
           _snormal[x][0][1] = _normal[x][0][1];
           _snormal[x][FLOTSIZE-1][0] = _normal[x][FLOTSIZE-1][0];
           _snormal[x][FLOTSIZE-1][1] = _normal[x][FLOTSIZE-1][1];
        }

        memcpy((char*) &_snormal[0][0][0], (char*) &_normal[0][0][0], 3*sizeof(float)*FLOTSIZE);
        memcpy((char*) &_snormal[FLOTSIZE-1][0][0], (char*) &_normal[FLOTSIZE-1][0][0], 3*sizeof(float)*FLOTSIZE);


        /* calculate ourself normalization */

        for(x=0; x < FLOTSIZE; x++)
        {
           for(y=0; y < FLOTSIZE; y++)
           {


              sqroot = sqrt(_snormal[x][y][0]*_snormal[x][y][0] +
                            _snormal[x][y][1]*_snormal[x][y][1] +
                            0.0016f);


              _snormaln[x][y][0] = _snormal[x][y][0]/sqroot;
              _snormaln[x][y][1] = _snormal[x][y][1]/sqroot;
              _snormaln[x][y][2] = 0.04f/sqroot;             // _snormal[x][y][2] = 0.04


              // perturbate coordinates of background mapping with the components X,Y of normals...
              // simulate refraction

              _newuvmap[x][y][0] = _uvmap[x][y][0] + 0.05f*_snormaln[x][y][0];
              _newuvmap[x][y][1] = _uvmap[x][y][1] + 0.05f*_snormaln[x][y][1];

           }
        }



        // really simple version of a fake envmap generator

        for(x=0; x < FLOTSIZE; x++)
        {
           for(y=0; y < FLOTSIZE; y++)
           {
              // trick : xy projection of normals  ->  assume reflection in direction of the normals
              //                                       looks ok for non-plane surfaces
              _envmap[x][y][0] = 0.5f + _snormaln[x][y][0]*0.45f;
              _envmap[x][y][1] = 0.5f + _snormaln[x][y][1]*0.45f;

           }
        }


   } // end low tesselation

}







//----------------------------------------
// display geometric model
//----------------------------------------

void dmFlotte::display(void)
{
   int strip_width;


   if (_hightesselation)
   {
      strip_width = FLOTSIZE*2-1-1;
   }
   else
   {
      strip_width = FLOTSIZE-1-1;
   }

   {

     // 2 pass rendering - 1 texture/pass (2 times polygons)

     // OpenGL specific
    glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    register int x,y;

    //printf("Texture 1\n");
	   
    if (_textured)
    {
        glEnable(GL_TEXTURE_2D);
        glDisable(GL_BLEND);


		
        glBindTexture(GL_TEXTURE_2D, 2); // 2nd texture -> background ..
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

		
		
        /* enable texture mapping and specify ourself texcoords */
#pragma mark Radif removed this
       // glDisable(GL_TEXTURE_2D);
        //glDisable(GL_BLEND);

    }

	  


     // build triangle strips ...

    float myTex[100][2] = {0.0f, 0.0f};
    float myVer[100][3] = {0.0f, 0.0f, 0.0f};

	   
	  	   
	   
    if (_lowtesselation)
    {
        //printf("strip_width: %d\n", strip_width);

        for(x=0; x<strip_width; x+=2)
        {
            int i = 0;

			i++;

            

            myTex[i-1][0] = _newuvmap[x+2][2][0];
            myTex[i-1][1] = _newuvmap[x+2][2][1];
            myVer[i-1][0] = _sommet[x+2][2][0];
            myVer[i-1][1] = _sommet[x+2][2][1];
            myVer[i-1][2] = _sommet[x+2][2][2];

            for(y=2; y<strip_width; y+=2)
            {
                i++;

                myTex[i-1][0] = _newuvmap[x][y][0];
                myTex[i-1][1] = _newuvmap[x][y][1];
                myVer[i-1][0] = _sommet[x][y][0];
                myVer[i-1][1] = _sommet[x][y][1];
                myVer[i-1][2] = _sommet[x][y][2];

                i++;


                myTex[i-1][0] = _newuvmap[x+2][y+2][0];
                myTex[i-1][1] = _newuvmap[x+2][y+2][1];
                myVer[i-1][0] = _sommet[x+2][y+2][0];
                myVer[i-1][1] = _sommet[x+2][y+2][1];
                myVer[i-1][2] = _sommet[x+2][y+2][2];
            }


            i++;

            //glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            glTexCoordPointer(2, GL_FLOAT, 0, _newuvmap[x][y]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

            myTex[i-1][0] =  _newuvmap[x][y][0];
            myTex[i-1][1] = _newuvmap[x][y][1];
            myVer[i-1][0] = _sommet[x][y][0];
            myVer[i-1][1] = _sommet[x][y][1];
            myVer[i-1][2] = _sommet[x][y][2];

           //glEnd();
           //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4* strip_width);
           glTexCoordPointer(2, GL_FLOAT, 0, myTex);
           glVertexPointer(3, GL_FLOAT, 0, myVer);
           glDrawArrays(GL_TRIANGLE_STRIP, 0, i);

           //printf("Vertices : i %d formula %d\n", i, 1 + 1 + (strip_width - 2 - 1)/2);
        }
    }


     // change Z-buffer function to EQUAL
     // so it will trace second geometry on the same layer (and avoid tracing if some
     // objects are before ...

     //glDepthFunc(GL_EQUAL);
     glDepthFunc(GL_LESS);
     //printf("Texture 2\n");

     if (_textured)
     {
        if (TEX_COMP1 == 4)
        {
           // change blending

           glEnable(GL_BLEND);

           // use texture alpha-channel for blending

           glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }

        glBindTexture(GL_TEXTURE_2D, 1); // 2nd texture -> envmap
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE); //GL_DECAL); // GL_REPLACE);

     }

    if (_lowtesselation)
    {
        for(x=0; x<strip_width; x+=2)
        {
            int i = 0;
            i++;
            myTex[i-1][0] = _envmap[x+2][2][0];
            myTex[i-1][1] = _envmap[x+2][2][1];
            myVer[i-1][0] = _sommet[x+2][2][0];
            myVer[i-1][1] = _sommet[x+2][2][1];
            myVer[i-1][2] = _sommet[x+2][2][2];

            for(y=2; y<strip_width; y+=2)
            {

                i++;
                myTex[i-1][0] = _envmap[x][y][0];
                myTex[i-1][1] = _envmap[x][y][1];
                myVer[i-1][0] = _sommet[x][y][0];
                myVer[i-1][1] = _sommet[x][y][1];
                myVer[i-1][2] = _sommet[x][y][2];
                i++;

                myTex[i-1][0] = _envmap[x+2][y+2][0];
                myTex[i-1][1] = _envmap[x+2][y+2][1];
                myVer[i-1][0] = _sommet[x+2][y+2][0];
                myVer[i-1][1] = _sommet[x+2][y+2][1];
                myVer[i-1][2] = _sommet[x+2][y+2][2];
            }

            i++;

            //glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            glTexCoordPointer(2, GL_FLOAT, 0, _envmap[x][y]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

            myTex[i-1][0] = _envmap[x][y][0];
            myTex[i-1][1] = _envmap[x][y][1];
            myVer[i-1][0] = _sommet[x][y][0];
            myVer[i-1][1] = _sommet[x][y][1];
            myVer[i-1][2] = _sommet[x][y][2];

            //glEnd();
            //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4*strip_width);
            glTexCoordPointer(2, GL_FLOAT, 0, myTex);
            glVertexPointer(3, GL_FLOAT, 0, myVer);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, i);

            //printf("Vertices : i %d formula %d\n", i, 1 + 1 + (strip_width - 2 - 1)/2);
        }
    }
    else // medium and high tesselation
    {
        for(x=0; x<strip_width; x++)
        {
            //glBegin(GL_TRIANGLE_STRIP);

            //glTexCoord2fv(_envmap[x+1][1]);
            //glVertex3fv(_sommet[x+1][1]);                               // otherwise everything is scrolled !!!

            glTexCoordPointer(2, GL_FLOAT, 0, _envmap[x+1][1]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x+1][1]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

           for(y=1; y<strip_width; y++)
           {
              //glTexCoord2fv(_envmap[x][y]);
              //glVertex3fv(_sommet[x][y]);
            glTexCoordPointer(2, GL_FLOAT, 0, _envmap[x][y]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

              //glTexCoord2fv(_envmap[x+1][y+1]);
              //glVertex3fv(_sommet[x+1][y+1]);
            glTexCoordPointer(2, GL_FLOAT, 0, _envmap[x+1][y+1]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x+1][y+1]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
           }


           //glTexCoord2fv(_envmap[x][y]);
           //glVertex3fv(_sommet[x][y]);
            glTexCoordPointer(2, GL_FLOAT, 0, _envmap[x][y]);
            glVertexPointer(3, GL_FLOAT, 0, _sommet[x][y]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

           //glEnd();
           //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4 * (2 + (strip_width-1)) );
        }
     }

        glDepthFunc(GL_LESS);  // back to normal Z_buffer function

        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    } // end single texturing
}


//--------------------------------------------
// load a texture TEW_WIDTH*TEX_HEIGHT*3
//--------------------------------------------



void dmFlotte::_load_tex(int num, char *aName)
{
     FILE *f;
     int  tga_file = FALSE;
     int i,j;
     int nbcomp;
     gzFile              handle;
     int count;


     GLubyte tmp;


     if (num == 0)
     {
        nbcomp = TEX_COMP1;
     }
     else if (num == 1)
     {
        nbcomp = TEX_COMP2;
     }

     //printf("opening texture map file %s:\n", aName);


     // open a file .dat /.gzip
     handle = gzopen(aName, "rb");

     if (handle == NULL)
     {
        printf("error opening tex file\n");
     }


     // skip header

     count = gzread(handle, _TexBuff[num], 46-1 + (nbcomp-3));
     tga_file = TRUE; // we have a TGA -> swap ABGR and RGBA

     //printf("read %d bytes\n", count);


     if ((count = gzread(handle, _TexBuff[num],  nbcomp*_texwidth[num]*_texheight[num]))==-1)
     {
        //printf("read error\n");
     }
     //else
     //{
     //    //printf("read %d bytes\n", count);
     //}

     // swap BGR and RGB, BGRA and RGBA

     if (tga_file)
     {
        for(i=0; i<_texwidth[num]*_texheight[num]; i++)
        {

           for(j=0; j < (3 >> 1); j++)
           {
              tmp = (_TexBuff[num])[i*nbcomp+j];
              (_TexBuff[num])[i*nbcomp+j] = (_TexBuff[num])[i*nbcomp+3-1-j];
              (_TexBuff[num])[i*nbcomp+3-1-j] = tmp;
           }
        }
     }

     //printf("closing texture file\n");
     gzclose(handle);

}


//--------------------------------------------
// TEW_WIDTH*TEX_HEIGHT*3 to 256x256*3
//
// crappy downsampling used for
// Voodoo1/Voodoo2 compatibility (can't use
// texture with a definition higher than
// 256x256)
//--------------------------------------------


void dmFlotte::_reduce_tex(int num, GLubyte *map)   // downgrade to 256x256
{
   if (map)
   {
      int sizeX = _texwidth[num];
      int sizeY = _texheight[num];

      GLubyte *newmap = new GLubyte[((sizeX*sizeY) >> 2) * TEX_COMP2 * sizeof(GLubyte)];
      GLubyte *ptmap;

      int i,j,ki, kj;
      unsigned int rgb[3];

      for(ptmap = newmap, i=0; i < (sizeX >> 2); i++)
      {
        for(j=0; j < (sizeY >> 2); j++)
        {
           rgb[0] = 0; rgb[1] = 0; rgb[2] = 0;

           for(ki = (i << 2); ki < (i << 2)+4; ki++)
           {
             for(kj = (j << 2); kj < (j << 2)+4; kj++)
             {

                rgb[0] += map[ki*sizeX*TEX_COMP2 + kj*TEX_COMP2];
                rgb[1] += map[ki*sizeX*TEX_COMP2 + kj*TEX_COMP2 + 1];
                rgb[2] += map[ki*sizeX*TEX_COMP2 + kj*TEX_COMP2 + 2];
             }
           }

           // average
           *ptmap++ = (rgb[0] >> 4);
           *ptmap++ = (rgb[1] >> 4);
           *ptmap++ = (rgb[2] >> 4);

        }
      }


      memcpy(map, newmap, ((sizeX*sizeY) >> 2) * TEX_COMP2 * sizeof(GLubyte));

      delete[] newmap;
   }
}
