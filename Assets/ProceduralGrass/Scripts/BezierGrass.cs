using UnityEngine;

public class BezierGrass : MonoBehaviour
{
    // Bottom Points
    [SerializeField] Transform _bottom0 = null;
    [SerializeField] Transform _bottom1 = null;

    // Top Point
    [SerializeField] Transform _top = null;

    [SerializeField] Transform[] _points = new Transform[2];

    [SerializeField, Range(0, 1)] float _deltaTime = 0f;

    void Update()
    {
        Vector3 half = new Vector3(_bottom0.position.x, 0, _bottom0.position.z);
        Vector3 p0 = Vector3.Lerp(_bottom0.position, half, _deltaTime);
        Vector3 p1 = Vector3.Lerp(half, _top.position, _deltaTime);
        _points[0].position = Vector3.Lerp(p0, p1, _deltaTime);

        half = new Vector3(_bottom1.position.x, 0, _bottom1.position.z);
        p0 = Vector3.Lerp(_bottom1.position, half, _deltaTime);
        p1 = Vector3.Lerp(half, _top.position, _deltaTime);
        _points[1].position = Vector3.Lerp(p0, p1, _deltaTime);
    }

    void SetPoint(int index)
    {

    }
}
