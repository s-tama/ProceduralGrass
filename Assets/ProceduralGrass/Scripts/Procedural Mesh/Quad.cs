//
// Quad.cs
//

using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class Quad : MonoBehaviour
{

    [SerializeField] MeshFilter _meshFilter = null;
    [SerializeField] MeshRenderer _meshRenderer = null;

    [SerializeField] Material _material = null;

    [SerializeField] float _size = 1f;


    private void Start()
    {
        // Meshの頂点を設定する
        float size = _size / 2f;
        Vector3[] vertices = new Vector3[]
        {
            new Vector3(-size,  size, 0f),  // 左上
            new Vector3( size,  size, 0f),  // 右上
            new Vector3( size, -size, 0f),  // 右下
            new Vector3(-size, -size, 0f)   // 左下
        };

        // Meshのuvを設定する
        Vector2[] uv = new Vector2[]
        {
            new Vector2(0f, 0f),
            new Vector2(1f, 0f),
            new Vector2(1f, 1f),
            new Vector2(0f, 1f)
        };

        // Meshの法線を設定する
        Vector3[] normals = new Vector3[]
        {
            new Vector3(0f, 0f, -1f),
            new Vector3(0f, 0f, -1f),
            new Vector3(0f, 0f, -1f),
            new Vector3(0f, 0f, -1f)
        };

        // 頂点インデックスを設定
        int[] indices = new int[]
        {
            0, 1, 2,
            2, 3, 0
        };

        // Meshを生成
        Mesh mesh = new Mesh();
        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.normals = normals;
        mesh.triangles = indices;

        // 境界領域を計算（カリングに必要）
        mesh.RecalculateBounds();

        // メッシュを設定
        _meshFilter.mesh = mesh;
        _meshRenderer.material = _material;
    }
}
