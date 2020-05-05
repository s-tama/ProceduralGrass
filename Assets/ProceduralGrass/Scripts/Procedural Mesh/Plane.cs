//
// Plane.cs
//

using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class Plane : MonoBehaviour
{

    [SerializeField] MeshFilter _meshFilter = null;
    [SerializeField] MeshRenderer _meshRenderer = null;

    [SerializeField] Material _material = null;

    [SerializeField] int _segmentWidth = 6;
    [SerializeField] int _segmentHeight = 6;

    [SerializeField] float _size = 1f;


    private void Start()
    {
        List<Vector3> vertices = new List<Vector3>();
        List<Vector2> uv = new List<Vector2>();
        List<Vector3> normals = new List<Vector3>();

        // 頂点グリッドの位置の割合を算出
        // グリッド頂点の位置を（0～1）に補正する
        float w = 1f / (_segmentWidth - 1f);
        float h = 1f / (_segmentHeight - 1f);

        for(int row = 0; row < _segmentHeight; row++)
        {
            // 行の位置の割合
            float y = (float)row * h;

            for(int column = 0; column < _segmentWidth; column++)
            {
                // 行の位置の割合
                float x = (float)column * w;

                // 頂点情報を追加
                Vector3 vertex = new Vector3(
                    (x - 0.5f) * _size,
                    0f,
                    (y - 0.5f) * _size
                    );
                vertices.Add(vertex);

                // uv情報の追加
                uv.Add(new Vector2(x, y));

                // 法線情報の追加
                normals.Add(new Vector3(0f, -1f, 0f));
            }
        }

        List<int> indices = new List<int>();
        for(int y = 0; y < _segmentHeight - 1; y++)
        {
            for(int x = 0; x < _segmentWidth - 1; x++)
            {
                int index = y * _segmentWidth + x;

                int a = index;
                int b = index + 1;
                int c = index + 1 + _segmentWidth;
                int d = index + _segmentWidth;

                indices.AddRange(new int[] { a, b, c });
                indices.AddRange(new int[] { c, d, a });
            }
        }

        // Meshを生成
        Mesh mesh = new Mesh();
        mesh.vertices = vertices.ToArray();
        mesh.uv = uv.ToArray();
        mesh.normals = normals.ToArray();
        mesh.triangles = indices.ToArray();

        // 境界領域を計算（カリングに必要）
        mesh.RecalculateBounds();

        // メッシュを設定
        _meshFilter.mesh = mesh;
        _meshRenderer.material = _material;
    }
}
