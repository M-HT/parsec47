module abagames.p47.LineDrawData;

version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}

/**
 * Data for drawing lines.
 */
public class LineDrawData {
 public:
  GLfloat[] vertices;
  GLfloat[] colors;

  public void clearData()
  {
    vertices = [];
    colors = [];
  }

  public void draw()
  {
    const int numVertices = cast(int)(vertices.length / 3);

    if (numVertices > 0) {
      glEnableClientState(GL_VERTEX_ARRAY);

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(vertices.ptr));
      glDrawArrays(GL_LINES, 0, numVertices);

      glDisableClientState(GL_VERTEX_ARRAY);
    }
  }

  public void drawLuminous()
  {
    const int numVertices = cast(int)(colors.length / 4);

    if (numVertices > 0) {
      glEnableClientState(GL_VERTEX_ARRAY);
      glEnableClientState(GL_COLOR_ARRAY);

      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(vertices.ptr));
      glColorPointer(4, GL_FLOAT, 0, cast(void *)(colors.ptr));
      glDrawArrays(GL_LINES, 0, numVertices);

      glDisableClientState(GL_COLOR_ARRAY);
      glDisableClientState(GL_VERTEX_ARRAY);
    }
  }
}

