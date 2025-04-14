using UnityEngine;

[ExecuteInEditMode]
public class FaceDirectionUpdater : MonoBehaviour
{
    public Material faceMaterial;
    public Transform faceTransform; 

    void Update()
    {
        if (faceMaterial != null && faceTransform != null)
        {
            // 更新面部朝向
            faceMaterial.SetVector("_FaceForward", faceTransform.forward);
            faceMaterial.SetVector("_FaceUp", faceTransform.up);
            // Debug.Log($"Face Forward: {faceTransform.forward}"); 
            // Debug.Log($"Face up: {faceTransform.up}"); 
        }
        
    }
}