

#ifndef __FLOTTE_H__
#define __FLOTTE_H__

// define some booleans

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

// define some basic types

#ifndef BYTE
#define BYTE unsigned char
#endif

#ifndef WORD
#define WORD unsigned short int
#endif

#ifndef DWORD
#define DWORD unsigned int
#endif

// define some constants

#ifndef M_PI
#define M_PI 3.1415926535897
#endif

// number of textures ...
#define NB_TEX 2

// textures sizes ...

// size of 1st texture (fluid surface - envmap)
#define TEX_WIDTH1  256
#define TEX_HEIGHT1 256

// size of 2nd texture (picture in water)
#define TEX_WIDTH2  1024
#define TEX_HEIGHT2 1024

// nb of components of 1st texture (fluid surface - envmap)
#define TEX_COMP1 4
// nb of components of 2nd texture (picture in water)
#define TEX_COMP2 3



#define FLOTSIZE  50  /* grid of 50 x 50 fluid cells */
#define FLOT_MILX (FLOTSIZE >> 1)+1
#define FLOT_MILY (FLOTSIZE >> 1)+1
#define FLOT_LARG (FLOTSIZE >> 1)


#define FLOT_HIGHRES 2
#define FLOT_MEDIUMRES 1
#define FLOT_LOWRES 0

////////////////////////////////////////////////
// Definition of a class for the fluid effect //
////////////////////////////////////////////////

class dmFlotte
{

   private:

      int      _win; // handle window
      bool     _multitex;
      bool     _freezemultitex;
      bool     _hightesselation;
      bool     _lowtesselation;


      float    _last_msTime;
      float    _cur_msTime;



      // buffer texture of fluid (skin)

      int      _texwidth[2];
      int      _texheight[2];
      int      _textured;

      // we can load textures of different resolutions


      GLubyte *_TexBuff[NB_TEX]; // TEX_WIDTH*TEX_HEIGHT*3 ou 4

      // static buffers ...

      int  _Flot1[FLOTSIZE+2][FLOTSIZE+2];
      int  _Flot2[FLOTSIZE+2][FLOTSIZE+2];

      signed short int _Lisse[FLOTSIZE+2][FLOTSIZE+2]; // buffer used for smoothing operation


      int (*_p1)[FLOTSIZE+2][FLOTSIZE+2]; // pointer FRONT
      int (*_p2)[FLOTSIZE+2][FLOTSIZE+2]; // pointer BACK

      int   _angle;      // angle for wave generator


      // geometric construction (static number of vertices)


      float _sommet[FLOTSIZE*2][FLOTSIZE*2][3];        // vertices vector
      float _normal[FLOTSIZE*2][FLOTSIZE*2][3];        // quads normals
      float _snormal[FLOTSIZE*2][FLOTSIZE*2][3];       // vertices normals (average)
      float _snormaln[FLOTSIZE*2][FLOTSIZE*2][3];      // normalized vertices normals
      float _uvmap[FLOTSIZE*2][FLOTSIZE*2][2];         // background texture coordinates
      float _newuvmap[FLOTSIZE*2][FLOTSIZE*2][2];      // perturbated background coordinates -> refraction
      float _envmap[FLOTSIZE*2][FLOTSIZE*2][2];        // envmap coordinates...


      // private methods

      void _new_Flot(void);      // fluid calculus
      void _Lisse_Flot(void);    // smooth filter
      void _prebuild_Flot(void); // precalculate geometric stuffs
      void _build_Flot(void);    // build geometry
      void _load_tex(int num, char *aName); // load texture no i
      void _reduce_tex(int num, GLubyte *map); // downgrade to 256x256
      void _init_GfxContext(void); // initialize gfx context

   public:

   //--------------------------
   // public functions
   //--------------------------

      dmFlotte(int rez);
      ~dmFlotte(void);

      // initial conditions for fluid model
      void init_Flot(void);

      // trace a hole in the fluid cells at normalized coords
      void setWave(float aX, float aY, int aVal);

      // some waves using parametric curves
      void runWave(float aPhase, float aCos, float aSin, int aVal);
      // random hole
      void randomWave(void);

      // next step in fluid model
      void update(void);

      // build geometric model
      void build(void);

      // display resulting geometry
      void display(void);

      // measure elapsed time ...
      bool bench(float rate);

      void nexttime(void);

};

#endif // __FLOTTE_H__
