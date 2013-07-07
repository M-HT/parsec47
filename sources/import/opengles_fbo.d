import opengles;
import std.string;
import std.conv;

extern (C) {
    // EGL
    alias void function() __eglMustCastToProperFunctionPointerType;

    __eglMustCastToProperFunctionPointerType eglGetProcAddress(const char *procname);

    // GLES extensions
    const uint GL_NONE_OES                                             = 0;
    const uint GL_FRAMEBUFFER_OES                                      = 0x8D40;
    const uint GL_RENDERBUFFER_OES                                     = 0x8D41;
    const uint GL_RGBA4_OES                                            = 0x8056;
    const uint GL_RGB5_A1_OES                                          = 0x8057;
    const uint GL_RGB565_OES                                           = 0x8D62;
    const uint GL_DEPTH_COMPONENT16_OES                                = 0x81A5;
    const uint GL_RENDERBUFFER_WIDTH_OES                               = 0x8D42;
    const uint GL_RENDERBUFFER_HEIGHT_OES                              = 0x8D43;
    const uint GL_RENDERBUFFER_INTERNAL_FORMAT_OES                     = 0x8D44;
    const uint GL_RENDERBUFFER_RED_SIZE_OES                            = 0x8D50;
    const uint GL_RENDERBUFFER_GREEN_SIZE_OES                          = 0x8D51;
    const uint GL_RENDERBUFFER_BLUE_SIZE_OES                           = 0x8D52;
    const uint GL_RENDERBUFFER_ALPHA_SIZE_OES                          = 0x8D53;
    const uint GL_RENDERBUFFER_DEPTH_SIZE_OES                          = 0x8D54;
    const uint GL_RENDERBUFFER_STENCIL_SIZE_OES                        = 0x8D55;
    const uint GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_OES               = 0x8CD0;
    const uint GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_OES               = 0x8CD1;
    const uint GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_OES             = 0x8CD2;
    const uint GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_OES     = 0x8CD3;
    const uint GL_COLOR_ATTACHMENT0_OES                                = 0x8CE0;
    const uint GL_DEPTH_ATTACHMENT_OES                                 = 0x8D00;
    const uint GL_STENCIL_ATTACHMENT_OES                               = 0x8D20;
    const uint GL_FRAMEBUFFER_COMPLETE_OES                             = 0x8CD5;
    const uint GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES                = 0x8CD6;
    const uint GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES        = 0x8CD7;
    const uint GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES                = 0x8CD9;
    const uint GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES                   = 0x8CDA;
    const uint GL_FRAMEBUFFER_UNSUPPORTED_OES                          = 0x8CDD;
    const uint GL_FRAMEBUFFER_BINDING_OES                              = 0x8CA6;
    const uint GL_RENDERBUFFER_BINDING_OES                             = 0x8CA7;
    const uint GL_MAX_RENDERBUFFER_SIZE_OES                            = 0x84E8;
    const uint GL_INVALID_FRAMEBUFFER_OPERATION_OES                    = 0x0506;

    alias GLboolean function (GLuint renderbuffer) PFNGLISRENDERBUFFEROESPROC;
    alias void function (GLenum target, GLuint renderbuffer) PFNGLBINDRENDERBUFFEROESPROC;
    alias void function (GLsizei n, const GLuint* renderbuffers) PFNGLDELETERENDERBUFFERSOESPROC;
    alias void function (GLsizei n, GLuint* renderbuffers) PFNGLGENRENDERBUFFERSOESPROC;
    alias void function (GLenum target, GLenum internalformat, GLsizei width, GLsizei height) PFNGLRENDERBUFFERSTORAGEOESPROC;
    alias void function (GLenum target, GLenum pname, GLint* params) PFNGLGETRENDERBUFFERPARAMETERIVOESPROC;
    alias GLboolean function (GLuint framebuffer) PFNGLISFRAMEBUFFEROESPROC;
    alias void function (GLenum target, GLuint framebuffer) PFNGLBINDFRAMEBUFFEROESPROC;
    alias void function (GLsizei n, const GLuint* framebuffers) PFNGLDELETEFRAMEBUFFERSOESPROC;
    alias void function (GLsizei n, GLuint* framebuffers) PFNGLGENFRAMEBUFFERSOESPROC;
    alias GLenum function (GLenum target) PFNGLCHECKFRAMEBUFFERSTATUSOESPROC;
    alias void function (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer) PFNGLFRAMEBUFFERRENDERBUFFEROESPROC;
    alias void function (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level) PFNGLFRAMEBUFFERTEXTURE2DOESPROC;
    alias void function (GLenum target, GLenum attachment, GLenum pname, GLint* params) PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVOESPROC;
    alias void function (GLenum target) PFNGLGENERATEMIPMAPOESPROC;
}


PFNGLBINDFRAMEBUFFEROESPROC glBindFramebufferOES;
PFNGLDELETEFRAMEBUFFERSOESPROC glDeleteFramebuffersOES;
PFNGLGENFRAMEBUFFERSOESPROC glGenFramebuffersOES;
//PFNGLCHECKFRAMEBUFFERSTATUSOESPROC glCheckFramebufferStatusOES;
PFNGLFRAMEBUFFERTEXTURE2DOESPROC glFramebufferTexture2DOES;


bool loadFBOExtension() {
    bool fboExtensionAvailable = false;
    bool fboFunctionsAvailable = false;

    glBindFramebufferOES = null;
    glDeleteFramebuffersOES = null;
    glGenFramebuffersOES = null;
    //glCheckFramebufferStatusOES = null;
    glFramebufferTexture2DOES = null;

    string extensions = to!string(cast(char *)glGetString(GL_EXTENSIONS));
    string extleft = extensions;

    while (extleft.length != 0) {
        ptrdiff_t delim = indexOf(extleft, ' ');
        string extension;
        if (delim != -1) {
            extension = extleft[0..delim];
            extleft = extleft[delim+1..extleft.length];
        } else {
            extension = extleft;
            extleft = extleft[0..0];
        }

        if (extension == "GL_OES_framebuffer_object") {
            fboExtensionAvailable = true;
            break;
        }
    }

    if (fboExtensionAvailable) {
        glBindFramebufferOES = cast(PFNGLBINDFRAMEBUFFEROESPROC) eglGetProcAddress(toStringz("glBindFramebufferOES"));
        glDeleteFramebuffersOES = cast(PFNGLDELETEFRAMEBUFFERSOESPROC) eglGetProcAddress(toStringz("glDeleteFramebuffersOES"));
        glGenFramebuffersOES = cast(PFNGLGENFRAMEBUFFERSOESPROC) eglGetProcAddress(toStringz("glGenFramebuffersOES"));
        //glCheckFramebufferStatusOES = cast(PFNGLCHECKFRAMEBUFFERSTATUSOESPROC) eglGetProcAddress(toStringz("glCheckFramebufferStatusOES"));
        glFramebufferTexture2DOES = cast(PFNGLFRAMEBUFFERTEXTURE2DOESPROC) eglGetProcAddress(toStringz("glFramebufferTexture2DOES"));

        fboFunctionsAvailable = (glBindFramebufferOES != null)
                             && (glDeleteFramebuffersOES != null)
                             && (glGenFramebuffersOES != null)
                             //&& (glCheckFramebufferStatusOES != null)
                             && (glFramebufferTexture2DOES != null);
    }

    return fboExtensionAvailable && fboFunctionsAvailable;
}

