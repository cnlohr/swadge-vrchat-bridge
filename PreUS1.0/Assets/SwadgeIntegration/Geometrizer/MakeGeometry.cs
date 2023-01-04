#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class MakeGeometry : MonoBehaviour
{
	[MenuItem("Tools/Geometrizer-MakeGeometry")]
	static void CreateMesh_()
	{
		// Generate 125 ships.
		// Each has 4 "boolets"
		
		const float bananaScale = 3.0f;
		const float shipScale = 1.0f;
		
		const int ships = 90;
		const int boolets = ships*4;
		
		Mesh banana = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/SwadgeIntegration/Geometrizer/MAGFest-Banana.fbx");
 		Mesh ship   = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/SwadgeIntegration/Geometrizer/SwadgeWing.fbx");

		int[] bananaIndices = banana.GetIndices( 0, true ); 
		int[] shipIndices = banana.GetIndices( 0, true ); 

		Debug.Log( banana.vertices.Length );
		Debug.Log( ship.vertices.Length );
		Debug.Log( bananaIndices.Length );
		Debug.Log( shipIndices.Length );

		Mesh mesh = new Mesh();
		
		int trueverts = banana.vertices.Length * boolets + ship.vertices.Length * ships;
		int trueinds  = bananaIndices.Length * boolets + shipIndices.Length * ships;
		int[] vertexStarts = new int[ships+boolets];
		int[] indices = new int[trueinds];
		Vector3[] vertices = new Vector3[trueverts];
		Vector3[] normals = new Vector3[trueverts];
		Vector3[] uvs = new Vector3[trueverts];
		
		int ino = 0;
		int vno = 0;
		int i, j;
		for( i = 0; i < ships+boolets; i++ )
		{
			bool bIsShip = ( (i % 5) == 0 );
			Mesh m = bIsShip ? ship : banana;
			int[] inds = m.GetIndices( 0, true );
			int vstart = vno;
			int istart = ino;
			for( j = 0; j < m.vertices.Length; j++ )
			{
				vertices[vno] = m.vertices[j] * (bIsShip?shipScale:bananaScale);
				normals[vno] = m.normals[j];
				uvs[vno] = new Vector3( m.uv[j].x, m.uv[j].y, i );
				vno++;
			}
			for( j = 0; j < inds.Length; j++ )
			{
				indices[ino++] = inds[j] + vstart;
			}
		}
		
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.SetUVs( 0, uvs );
		mesh.bounds = new Bounds(new Vector3(0,28,15), new Vector3(40*2, 40*2, 60*2));
		mesh.SetIndices(indices, MeshTopology.Triangles, 0, false, 0);
		AssetDatabase.CreateAsset(mesh, "Assets/SwadgeIntegration/Geometrizer/SwadgeGeometry.asset");
	}
}
#endif